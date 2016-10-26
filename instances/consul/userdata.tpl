#!/bin/bash -ex

# Debian apt-get install function to eliminate prompts
export DEBIAN_FRONTEND=noninteractive
apt_get_install()
{
    DEBIAN_FRONTEND=noninteractive apt-get -y \
	-o DPkg::Options::=--force-confnew \
	install $@
}

# Update the packace indexes
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confnew" upgrade

# Install basic APT packages and requirements
apt_get_install atop dstat htop jq linux-tools-common python-software-properties
apt_get_install sysstat tree unzip util-linux xinetd zip
apt_get_install python-setuptools python-pip
apt_get_install ntp

# Configure NTP
service ntp stop		# Stop ntp daemon to free NTP socket
sleep 3				# Give the daemon some time to exit
ntpdate pool.ntp.org		# Sync time
service ntp start		# Re-enable the NTP daemon

# Configure automatic security updates
cat > /etc/apt/apt.conf.d/20auto-upgrades << "EOF"
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
/etc/init.d/unattended-upgrades restart

# Update system limits
cat > /etc/security/limits.d/ap_limits.conf << "EOF"
*               soft    nofile          999999
*               hard    nofile          999999
root            soft    nofile          999999
root            hard    nofile          999999
EOF
ulimit -n 999999

# Mark successful execution
exit 0
