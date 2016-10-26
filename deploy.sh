#!/usr/bin/env bash

## Original: https://github.com/natelandau/shell-scripts

version="0.1"
scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
utilsLocation="${scriptPath}/scripts/lib/utils.sh"

if [ -f "${utilsLocation}" ]; then
  source "${utilsLocation}"
else
  echo "Please find util.sh and add a reference to it in this script. Exiting."
  exit 1
fi

# trapCleanup Function
# -----------------------------------
# Any actions that should be taken if the script is prematurely
# exited.  Always call this function at the top of your script.
# -----------------------------------
function trapCleanup() {
  echo ""
  # Delete temp files, if any
  if is_dir "${tmpDir}"; then
    rm -r "${tmpDir}"
  fi
  die "Exit trapped. In function: '${FUNCNAME[*]}'"
}

# safeExit
# -----------------------------------
# Non destructive exit for when script exits naturally.
# Usage: Add this function at the end of every script.
# -----------------------------------
function safeExit() {
  # Delete temp files, if any
  if is_dir "${tmpDir}"; then
    rm -r "${tmpDir}"
  fi
  trap - INT TERM EXIT
  exit
}

# Set Flags
# -----------------------------------
# Flags which can be overridden by user input.
# Default values are below
# -----------------------------------
quiet=false
printLog=false
verbose=false
force=false
strict=false
debug=false
args=()

# Create temp directory with three random numbers and the process ID
# in the name.  This directory is removed automatically at exit.
tmpDir="/tmp/${scriptName}.$RANDOM.$RANDOM.$RANDOM.$$"
(umask 077 && mkdir "${tmpDir}") || {
  die "Could not create temporary directory! Exiting."
}

# Log is only used when the '-l' flag is set.
logFile="/tmp/${scriptBasename}.log"

#envDependencies=( EC2_REGION  )

function prereqOSX() {
    openssl=false

    brew=$(which brew || true)
    if [[ -z "$brew" ]]; then
        openssl=true
    else
        info "Installing openssl using Homebrew..."
        brew update
        brew install openssl
    fi

    if [[ "$openssl" = false ]]; then
        port=$(which port || true)
        if [[ -z "$port" ]]; then
            openssl=1
        else
            info "Installing openssl using MacPorts..."
            info "I need to be sudo..."
            sudo port selfupdate
            sudo port install openssl
        fi
    fi

    if [[ "$openssl" = false ]]; then
        die "Neither Homebrew nor MacPorts is installed. I need one of those."
    fi
}

function mainScript() {
    echo ""
    echo -e "${bold}${green}I need few things from you to get started..."
    echo ""

    # Get all required input from user
    read -s -p "AWS Acess Key  : " AWS_ACCESS_KEY
    echo ""
    read -s -p "AWS Secret Key : " AWS_SECRET_ACCESS_KEY
    echo ""
    read -p "AWS EC2 Region (e.g. us-east-1): " EC2_REGION
    echo ""
    read -p "VPC Name (e.g. prod) : " VPC_NAME
    read -p "VPC DOMAIN (e.g. example.com) : " VPC_DOMAIN
    read -p "VPC CIDR Block (pick a /16, e.g. 10.10.0.0/16) : " VPC_CIDR_BLOCK
    echo ""
    info "Now, I need your egreess IP. Go to http://whatismyip.com and find out"
    read -p "${bold}${green}Egress IP : " EGRESS_IP
    echo ""

    # Ensure pyenv is present and activate it
    if is_os "linux"; then
        prereqLinux
    elif is_os "darwin"; then
        prereqOSX
    fi

    if [ ! -d "$scriptPath/pyenv" ]; then
        # setup our virtualenv
        info "Installing virtualenv (sudo required)..."
        sudo pip install virtualenv
        virtualenv pyenv
        source "$scriptPath/pyenv/bin/activate"
        pip install --upgrade pip
        brew=$(which brew || true)
        if [[ -z "$brew" ]]; then
            # We have MacPorts
            ARCHFLAGS="-arch x86_64" LDFLAGS="-L/opt/local/lib" \
            CFLAGS="-I/opt/local/include" \
            pip install -r "$scriptPath/requirements.txt"
        else
            LDFLAGS="-L$(brew --prefix openssl)/lib" \
            CFLAGS="-I$(brew --prefix openssl)/include" \
            pip install -r "$scriptPath/requirements.txt"
        fi
    else
        source "$scriptPath/pyenv/bin/activate"
    fi

    ## Setup terraform
    if [[ ! -e "$scriptPath/terraform" ]]; then
        ver="0.7.7"
        file_name=""
        if is_os "linux"; then
            file_name="terraform_${ver}_linux_amd64.zip"
        elif is_os "darwin"; then
            file_name="terraform_${ver}_darwin_amd64.zip"
        fi
        curl -s --remote-name \
            "https://releases.hashicorp.com/terraform/$ver/$file_name"
        unzip "$file_name"
        chmod +x ./terraform
    fi

    ## Set the relevant environment vars and proceed
    export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
    export EC2_REGION="$EC2_REGION"
    export VPC_NAME="$VPC_NAME"
    export VPC_CIDR_BLOCK="$VPC_CIDR_BLOCK"
    export VPC_DOMAIN="$VPC_DOMAIN"
    export SSH_KEY_FILE="$scriptPath/${VPC_NAME}_ssh"
    export EGRESS_IPS="[\"$EGRESS_IP/32\"]"
    export ANSIBLE_DIR="$scriptPath/ansible"

    ## Generate SSH Key if it doesn't exist
    if [[ ! -e "$SSH_KEY_FILE" ]]; then
        ssh-keygen -b 2048 -t rsa -f "$SSH_KEY_FILE" -q -N ""
    fi

    eval "cat <<EOF
$(<${scriptPath}/variables.tf.tmpl)
EOF
    " > "${scriptPath}/variables.tf"

    # Run terraform
    info "[terraform] Creating plan"
    "$scriptPath/terraform" get
    "$scriptPath/terraform" plan -out="$VPC_NAME.tfplan"
    echo ""

    seek_confirmation "Is the plan acceptable?"
    if is_confirmed; then
        info "[terraform] Applying the plan"
        "$scriptPath/terraform" apply "$VPC_NAME.tfplan"
    else
        info "As you wish..."
    fi
}


# Print usage
usage() {
  echo -n "${scriptName} [OPTION]... [FILE]...

Script to invoke provisioning of a reference stack in AWS

 ${bold}Options:${reset}
  -q, --quiet       Quiet (no output)
  -l, --log         Print log to file
  -d, --debug       Runs script in BASH debug mode (set -x)
  -h, --help        Display this help and exit
      --version     Output version information and exit
"
}

# Iterate over options breaking -ab into -a -b when needed and --foo=bar into
# --foo bar
optstring=h
unset options
while (($#)); do
  case $1 in
    # If option is of type -ab
    -[!-]?*)
      # Loop over each character starting with the second
      for ((i=1; i < ${#1}; i++)); do
        c=${1:i:1}

        # Add current char to options
        options+=("-$c")

        # If option takes a required argument, and it's not the last char make
        # the rest of the string its argument
        if [[ $optstring = *"$c:"* && ${1:i+1} ]]; then
          options+=("${1:i+1}")
          break
        fi
      done
      ;;

    # If option is of type --foo=bar
    --?*=*) options+=("${1%%=*}" "${1#*=}") ;;
    # add --endopts for --
    --) options+=(--endopts) ;;
    # Otherwise, nothing special
    *) options+=("$1") ;;
  esac
  shift
done
set -- "${options[@]}"
unset options

# Print help if no arguments were passed.
# Uncomment to force arguments when invoking the script
# [[ $# -eq 0 ]] && set -- "--help"

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) usage >&2; safeExit ;;
    --version) echo "$(basename $0) ${version}"; safeExit ;;
    -l|--log) printLog=true ;;
    -q|--quiet) quiet=true ;;
    -s|--strict) strict=true;;
    -d|--debug) debug=true;;
    --force) force=true ;;
    --endopts) shift; break ;;
    *) die "invalid option: '$1'." ;;
  esac
  shift
done

# Store the remaining part as arguments.
args+=("$@")

############## End Options and Usage ###################

## Nothing to see here, anything you want to do, probably
## needs to be done above me.

# Trap bad exits with your cleanup function
trap trapCleanup EXIT INT TERM

# Set IFS to preferred implementation
IFS=$'\n\t'

# Exit on error. Append '||true' when you run the script if you expect an error.
set -o errexit

# Run in debug mode, if set
if ${debug}; then set -x ; fi

# Exit on empty variable
if ${strict}; then set -o nounset ; fi

# Bash will remember & return the highest exitcode in a chain of pipes.
# This way you can catch the error in case mysqldump fails in `mysqldump |gzip`, for example.
set -o pipefail

# Check all the dependencies
checkDependencies

# Run your script
mainScript

# Exit cleanlyd
safeExit
