#RPi4B with Ubuntu script
sudo apt update
sudo apt -y full-upgrade
sudo apt -y autoremove
sudo apt -y autoclean
sudo apt install -y unbound
sudo wget https://www.internic.net/domain/named.root -O /etc/unbound/root.hints
{
	echo 'server:'
	echo 'directory: "/etc/unbound"'
	echo 'username: "unbound"'
	echo 'pidfile: "/etc/unbound/unbound.pid"'
	echo 'verbosity: 0'
	echo 'interface: 127.0.0.1'
	echo 'port: 5335'
	echo 'do-ip4: yes'
	echo 'do-ip6: no'
	echo 'do-udp: yes'
	echo 'do-tcp: yes'
	echo 'prefer-ip6: no'
	echo 'harden-glue: yes'
	echo 'harden-dnssec-stripped: yes'
	echo 'cache-min-ttl: 3600'
	echo 'cache-max-ttl: 86400'
	echo 'use-caps-for-id: no'
	echo 'edns-buffer-size: 1472'
	echo 'infra-cache-numhosts: 50000'
	echo 'prefetch: yes'
	echo 'num-queries-per-thread: 2048'
	echo 'num-threads: 4'
	echo 'msg-cache-slabs: 8'
	echo 'rrset-cache-slabs: 8'
	echo 'infra-cache-slabs: 8'
	echo 'key-cache-slabs: 8'
	echo 'rrset-cache-size: 64m'
	echo 'msg-cache-size: 32m'
	echo 'so-rcvbuf: 1m'
	echo 'unwanted-reply-threshold: 10000'
	echo 'private-address: 192.168.0.0/16'
	echo 'private-address: 169.254.0.0/16'
	echo 'private-address: 172.16.0.0/12'
	echo 'private-address: 10.0.0.0/8'
	echo 'private-address: fd00::/8'
	echo 'private-address: fe80::/10'
	echo '#private-domain:'
	echo '#domain-insecure:'
	echo 'tls-cert-bundle: /etc/ssl/certs/ca-certificates.crt'
	echo 'forward-zone:'
	echo 'name: "."'
	echo 'forward-tls-upstream: yes'
	echo 'forward-addr: 1.1.1.1@853'
	echo 'forward-addr: 1.0.0.1@853'
	echo 'remote-control:'
	echo 'control-enable: yes'
	echo 'server-key-file: "/etc/unbound/unbound_server.key"'
	echo 'server-cert-file: "/etc/unbound/unbound_server.pem"'
	echo 'control-key-file: "/etc/unbound/unbound_control.key"'
	echo 'control-cert-file: "/etc/unbound/unbound_control.pem"'
} >> pihole.conf
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
mkdir /etc/pihole
{
	echo 'WEBPASSWORD='
	echo 'PIHOLE_INTERFACE='$main_int
	echo 'IPV4_ADDRESS='$assigned_ip
	echo 'IPV6_ADDRESS='
	echo 'QUERY_LOGGING=true'
	echo 'INSTALL_WEB=true'
	echo 'DNSMASQ_LISTENING=single'
	echo 'PIHOLE_DNS_1=127.0.0.1#5335'
	echo 'PIHOLE_DNS_2='
	echo 'PIHOLE_DNS_3='
	echo 'PIHOLE_DNS_4='
	echo 'DNS_FQDN_REQUIRED=true'
	echo 'DNS_BOGUS_PRIV=true'
	echo 'DNSSEC=true'
	echo 'TEMPERATUREUNIT=F'
	echo 'WEBUIBOXEDLAYOUT=traditional'
	echo 'API_EXCLUDE_DOMAINS='
	echo 'API_EXCLUDE_CLIENTS='
	echo 'API_QUERY_LOG_SHOW=all'
	echo 'API_PRIVACY_MODE=false'
	
} >> ~/setupVars.conf
sudo mv ~/setupVars.conf /etc/pihole/setupVars.conf
sudo curl -sSL https://install.pi-hole.net​ | bash /dev/stdin --unattended
echo "Enter password for PiHole web interface (leave blank for no password)"
pihole -a -p
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