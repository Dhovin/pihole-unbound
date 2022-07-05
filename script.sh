#!/bin/bash
#RPi4B with Ubuntu script
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi


echo "***  UPDATING REPOSITORIES  ***"
sudo apt update
echo "***  UPGRADING ALL MODULES  ***"
sudo apt -y full-upgrade
echo "***  REMOVING UNUSED MODULES  ***"
sudo apt -y autoremove
echo "*** CLEANING OLD MODULES VERSIONS  ***"
sudo apt -y autoclean
echo "*** INSTALLING UNBOUND  ***"
sudo apt install -y unbound
sudo wget https://www.internic.net/domain/named.root -O /etc/unbound/root.hints
sudo wget https://raw.githubusercontent.com/Dhovin/pihole-unbound/main/pihole.conf -O /etc/unbound/unbound.conf.d/pihole.conf
echo "***  RESTARTING UNBOUND SERVICE  ***"
sudo service unbound restart
echo "***  PREPPING PIHOLE INSTALL  ***"
main_int=$(ip route get 8.8.8.8 | awk -- '{printf $5}')
echo "Enter static ip address in CIDR notation [1.1.1.1/24]"
read -p 'Static IP: ' assigned_ip
read -p 'Gateway IP: ' gateway
echo "Enter name server IP addresses seperated by comma"
read -p 'Nameserver: ' nameservers
sudo netplan set ethernets.$main_int.dhcp4=false
sudo netplan set ethernets.$main_int.addresses=[$assigned_ip]
sudo netplan set ethernets.$main_int.gateway4=$gateway
sudo netplan set ethernets.$main_int.nameservers.addresses=[$nameservers]
sudo netplan apply
sudo sed 's/#NTP=/NTP=0.us.pool.ntp.org/' /etc/systemd/timesyncd.conf
sudo timedatectl set-ntp true
sudo systemctl daemon-reload
sudo systemctl restart systemd-timesyncd.service
sudo dpkg-reconfigure tzdata
sudo mkdir /etc/pihole
{
	echo 'WEBPASSWORD='
	echo 'PIHOLE_INTERFACE='$main_int
	echo 'IPV4_ADDRESS='$assigned_ip
	echo 'IPV6_ADDRESS='
	echo 'QUERY_LOGGING=true'
	echo 'INSTALL_WEB_SERVER=true'
	echo 'INSTALL_WEB_INTERFACE=true'
	echo 'DNSMASQ_LISTENING=local'
	echo 'PIHOLE_DNS_1=127.0.0.1#5335'
	echo 'DNS_FQDN_REQUIRED=true'
	echo 'DNS_BOGUS_PRIV=true'
	echo 'ADMIN_EMAIL='
	echo 'WEBTHEME=default-auto'
	echo 'DNSSEC=true'
	echo 'TEMPERATUREUNIT=F'
	echo 'WEBUIBOXEDLAYOUT=boxed'
	echo 'API_EXCLUDE_DOMAINS='
	echo 'API_EXCLUDE_CLIENTS='
	echo 'API_QUERY_LOG_SHOW=all'
	echo 'API_PRIVACY_MODE=false'
	
} >> ~/setupVars.conf
sudo mv ~/setupVars.conf /etc/pihole/setupVars.conf
sudo curl -sSL https://install.pi-hole.net​ | bash /dev/stdin --unattended
echo "Enter password for PiHole web interface (leave blank for no password)"
sudo pihole -a -p
cd /home
sudo mkdir pihole
sudo chown pihole:pihole pihole
cd pihole
sudo mkdir .gnupg
sudo chown pihole:pihole .gnupg
sudo chmod 700 .gnupg
cd /var/www
sudo mkdir .gnupg
sudo chown www-data:www-data .gnupg
sudo chmod 700 .gnupg