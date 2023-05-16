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
apt update
printf "\033[92m***  UPGRADING ALL MODULES  ***\033[0m\n\r"
apt -y full-upgrade
printf "\033[92m***  REMOVING UNUSED MODULES  ***\033[0m\n\r"
apt -y autoremove
printf "\033[92m*** CLEANING OLD MODULES VERSIONS  ***\033[0m\n\r"
apt -y autoclean
printf "\033[92m*** INSTALLING UNBOUND  ***\033[0m\n\r"
sed -i '$ a net.core.rmem_max=1048576' /etc/sysctl.conf
wget https://raw.githubusercontent.com/Dhovin/pihole-unbound/main/dockerunbound.sh
chmod +x unbound.sh
./unbound.sh
#apt install -y unbound
#wget https://www.internic.net/domain/named.root -O /etc/unbound/root.hints
#wget https://raw.githubusercontent.com/Dhovin/pihole-unbound/main/pihole.conf -O /etc/unbound/unbound.conf.d/pihole.conf
#printf "\033[92m***  RESTARTING UNBOUND SERVICE  ***\033[0m\n\r"
#service unbound restart
printf "\033[92m***  PREPPING PIHOLE INSTALL  ***\033[0m\n\r"
main_int=$(ip route get 8.8.8.8 | awk -- '{printf $5}')
printf "\033[92mEnter static ip address in CIDR notation [1.1.1.1/24]\033[0m\n\r"
read -p 'Static IP: ' assigned_ip
read -p 'Gateway IP: ' gateway
printf "\033[92mEnter name server IP addresses seperated by comma\033[0m\n\r"
read -p 'Nameserver: ' nameservers
if [[ "$VER" == 18.04 ]]; then
	linenum=$(grep -n "dhcp4: true" /etc/netplan/00-installer-config.yaml | awk -- '{printf $1}' | sed 's/://')
	sed -i 's/dhcp4: true/dhcp4: false/' /etc/netplan/00-installer-config.yaml
	linenum=$(expr $((linenum + 1)))
	sed -i "$linenum i\      addresses:" /etc/netplan/00-installer-config.yaml
	linenum=$(expr $((linenum + 1)))
	sed -i "$linenum i\        - $assigned_ip" /etc/netplan/00-installer-config.yaml
	linenum=$(expr $((linenum + 1)))
	sed -i "$linenum i\      gateway4: $gateway" /etc/netplan/00-installer-config.yaml
	linenum=$(expr $((linenum + 1)))
	sed -i "$linenum i\      nameservers:" /etc/netplan/00-installer-config.yaml
	linenum=$(expr $((linenum + 1)))
	sed -i "$linenum i\        addresses: [$nameservers]" /etc/netplan/00-installer-config.yaml
	netplan try
elif [[ "$VER" == 20.04 ]]; then
	netplan set ethernets.$main_int.dhcp4=false
	netplan set ethernets.$main_int.addresses=[$assigned_ip]
	netplan set ethernets.$main_int.gateway4=$gateway
	netplan set ethernets.$main_int.nameservers.addresses=[$nameservers]
	netplan apply
fi

sed 's/#NTP=/NTP=0.us.pool.ntp.org/' /etc/systemd/timesyncd.conf
timedatectl set-ntp true
systemctl daemon-reload
systemctl restart systemd-timesyncd.service
dpkg-reconfigure tzdata
mkdir /etc/pihole
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
mv ~/setupVars.conf /etc/pihole/setupVars.conf
curl -sSL https://install.pi-hole.net​ | bash /dev/stdin --unattended
printf "\033[92mEnter password for PiHole web interface (leave blank for no password)\033[0m\n\r"
pihole -a -p
cd /home
mkdir pihole
chown pihole:pihole pihole
cd pihole
mkdir .gnupg
chown pihole:pihole .gnupg
chmod 700 .gnupg
cd /var/www
mkdir .gnupg
chown www-data:www-data .gnupg
chmod 700 .gnupg
cd ~
shutdown -r now