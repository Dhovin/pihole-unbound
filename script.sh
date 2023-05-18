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

printf "\033[92m***  UPDATING REPOSITORIES  ***\033[0m\n\r"
sudo apt update
printf "\033[92m***  INSTALLING DEPENDANCIES  ***\033[0m\n\r"
sudo apt install -y curl
printf "\033[92m***  UPGRADING ALL MODULES  ***\033[0m\n\r"
sudo apt -y full-upgrade
printf "\033[92m***  REMOVING UNUSED MODULES  ***\033[0m\n\r"
sudo apt -y autoremove
printf "\033[92m*** CLEANING OLD MODULES VERSIONS  ***\033[0m\n\r"
sudo apt -y autoclean
printf "\033[92m*** INSTALLING UNBOUND  ***\033[0m\n\r"
sudo sed -i '$ a net.core.rmem_max=1048576' /etc/sysctl.conf
wget https://raw.githubusercontent.com/Dhovin/pihole-unbound/main/unbound.sh
sudo chmod +x unbound.sh
./unbound.sh
#sudo apt install -y unbound
#sudo wget https://www.internic.net/domain/named.root -O /etc/unbound/root.hints
#sudo wget https://raw.githubusercontent.com/Dhovin/pihole-unbound/main/pihole.conf -O /etc/unbound/unbound.conf.d/pihole.conf
#printf "\033[92m***  RESTARTING UNBOUND SERVICE  ***\033[0m\n\r"
#sudo service unbound restart
printf "\033[92m***  PREPPING PIHOLE INSTALL  ***\033[0m\n\r"
main_int=$(ip route get 8.8.8.8 | awk -- '{printf $5}')
printf "\033[92mEnter static ip address in CIDR notation [1.1.1.1/24]\033[0m\n\r"
read -p 'Static IP: ' assigned_ip
read -p 'Gateway IP: ' gateway
printf "\033[92mEnter name server IP addresses seperated by comma\033[0m\n\r"
read -p 'Nameserver: ' nameservers
if [[ "$VER" == 20.04 ]]; then
	sudo netplan set ethernets.$main_int.dhcp4=false
	sudo netplan set ethernets.$main_int.addresses=[$assigned_ip]
	sudo netplan set ethernets.$main_int.gateway4=$gateway
	sudo netplan set ethernets.$main_int.nameservers.addresses=[$nameservers]
	sudo netplan apply
fi

sudo sed 's/#NTP=/NTP=0.us.pool.ntp.org/' /etc/systemd/timesyncd.conf
sudo timedatectl set-ntp true
sudo systemctl daemon-reload
sudo systemctl restart systemd-timesyncd.service
sudo dpkg-reconfigure tzdata
sudo mkdir /etc/pihole
{
	printf 'WEBPASSWORD=\n'
	printf "PIHOLE_INTERFACE=$main_int\n"
	printf "IPV4_ADDRESS=$assigned_ip\n"
	printf 'IPV6_ADDRESS=\n'
	printf 'QUERY_LOGGING=true\n'
	printf 'INSTALL_WEB_SERVER=true\n'
	printf 'INSTALL_WEB_INTERFACE=true\n'
	printf 'DNSMASQ_LISTENING=local\n'
	printf 'PIHOLE_DNS_1=127.0.0.1#5335\n'
	printf 'DNS_FQDN_REQUIRED=true\n'
	printf 'DNS_BOGUS_PRIV=true\n'
	printf 'ADMIN_EMAIL=\n'
	printf 'WEBTHEME=default-auto\n'
	printf 'DNSSEC=true\n'
	printf 'TEMPERATUREUNIT=F\n'
	printf 'WEBUIBOXEDLAYOUT=boxed\n'
	printf 'API_EXCLUDE_DOMAINS=\n'
	printf 'API_EXCLUDE_CLIENTS=\n'
	printf 'API_QUERY_LOG_SHOW=all\n'
	printf 'API_PRIVACY_MODE=false\n'
	
} > ~/setupVars.conf
sudo mv ~/setupVars.conf /etc/pihole/setupVars.conf
curl -sSL https://install.pi-hole.net​ | sudo bash /dev/stdin --unattended
printf "\033[92mEnter password for PiHole web interface (leave blank for no password)\033[0m\n\r"
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
cd ~
sudo shutdown -r now