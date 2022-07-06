sudo apt update
sudo apt install -y build-essential libssl-dev libexpat1-dev checkinstall bison flex doxygen
#libsystemd-dev
printf "\033[92m***adding unbound group***\033[0m\n"
sudo groupadd -g 88 unbound
printf "\033[92m***adding unbound system user***\033[0m\n" 
sudo useradd -c "Unbound DNS Resolver" -d /var/lib/unbound -u 88 -g unbound -s /bin/false unbound
printf "\033[92m***downloading latest version of unbound software***\033[0m\n"
wget https://nlnetlabs.nl/downloads/unbound/unbound-latest.tar.gz
printf "\033[92m***creating build directory***\033[0m\n"
mkdir ~/unbound
printf "\033[92m***extracting archive***\033[0m\n"
tar xzf unbound-latest.tar.gz -C ~/unbound
cd unbound/
dir=$(ls)
cd $dir
printf "\033[92m***building unbound source***\033[0m\n"
#sudo ./configure --prefix=/usr --sysconfdir=/etc --disable-static --with-pidfile=/run/unbound.pid
sudo ./configure --prefix=/usr --includedir=/usr/include --disable-static --mandir=/usr/share/man --infodir=/usr/share/info --sysconfdir=/etc --localstatedir=/var --disable-rpath --with-pidfile=/run/unbound.pid --with-rootkey-file=/var/lib/unbound/root.key --enable-subnet --with-chroot-dir= --libdir=/usr/lib
#--with-libevent --enable-systemd
printf "\033[92m***compiling unbound***\033[0m\n"
sudo make
sudo make doc
printf "\033[92m***creating uninstaller file and installing unbound***\033[0m\n"
sudo checkinstall --fstrans=0 --pkgname=unbound --pkgversion=1.16.0 --default
#sudo make install
sudo install -v -m755 -d /usr/share/doc/unbound-1.16.0
sudo install -v -m644 doc/html/* /usr/share/doc/unbound-1.16.0
sudo tee -a ~/unbound.conf << EOF
# Unbound configuration file for Debian.
#
# See the unbound.conf(5) man page.
#
# See /etc/unbound/unbound.conf.bak for a commented
# reference config file.
#
# The following line includes additional configuration files from the
# /etc/unbound/unbound.conf.d directory.
include: "/etc/unbound/unbound.conf.d/*.conf"
EOF
sudo chown unbound:unbound /etc/unbound
printf "\033[92m***moving /etc/unbound/unbound.conf to unbound.conf.bak for future reference***\033[0m\n"
sudo mv /etc/unbound/unbound.conf /etc/unbound/unbound.conf.bak
sudo mv ~/unbound.conf /etc/unbound/unbound.conf
sudo wget https://www.internic.net/domain/named.root -O /etc/unbound/root.hints
sudo chown unbound:unbound /etc/unbound/*
sudo /usr/sbin/unbound-anchor -a /etc/unbound/root.key -v
sudo /usr/sbin/unbound-control-setup
sudo mkdir /etc/unbound/unbound.conf.d
sudo chown unbound:unbound /etc/unbound/unbound.conf.d
printf "\033[92m***creating /etc/unbound/unbound.conf.d/pi-hole.conf file***\033[0m\n"
sudo wget https://raw.githubusercontent.com/Dhovin/pihole-unbound/main/pihole.conf -O /etc/unbound/unbound.conf.d/pihole.conf
sudo chown unbound:unbound /etc/unbound/unbound.conf.d/*
sudo chmod -R 755 /etc/unbound/
printf "\033[92m***creating systemd service record***\033[0m\n"
sudo tee -a /lib/systemd/system/unbound.service << EOF
[Unit]
Description=Validating, recursive, and caching DNS resolver
Documentation=man:unbound(8)
Requires=network.target
After=network-online.target
Before=nss-lookup.target
Wants=network-online.target nss-lookup.target
[Install]
WantedBy=multi-user.target
[Service]
ExecStart=/usr/sbin/unbound -d -p
ExecReload=+/bin/kill -HUP $MAINPID
NotifyAccess=main
Type=notify
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_SETGID CAP_SETUID CAP_SYS_CHROOT CAP_SYS_RESOURCE CAP_NET_RAW
MemoryDenyWriteExecute=true
NoNewPrivileges=true
PrivateDevices=true
PrivateTmp=true
ProtectHome=true
ProtectClock=true
ProtectControlGroups=true
ProtectKernelLogs=true
ProtectKernelTunables=false
ProtectProc=invisible
ProtectSystem=strict
RuntimeDirectory=unbound
ConfigurationDirectory=unbound
StateDirectory=unbound
RestrictAddressFamilies=AF_INET AF_INET6 AF_NETLINK AF_UNIX
RestrictRealtime=true
SystemCallArchitectures=native
SystemCallFilter=~@clock @cpu-emulation @debug @keyring @module mount @obsolete @resources
RestrictNamespaces=yes
LockPersonality=yes
RestrictSUIDSGID=yes
ProtectKernelModules=true
ProtectKernelTunables=false
ProtectProc=invisible
ProtectSystem=strict
RuntimeDirectory=unbound
ConfigurationDirectory=unbound
StateDirectory=unbound
RestrictAddressFamilies=AF_INET AF_INET6 AF_NETLINK AF_UNIX
RestrictRealtime=true
SystemCallArchitectures=native
SystemCallFilter=~@clock @cpu-emulation @debug @keyring @module mount @obsolete @resources
RestrictNamespaces=yes
LockPersonality=yes
RestrictSUIDSGID=yes
ReadWritePaths=/run/unbound /var/lib/unbound
Restart=always
RestartSec=120
EOF
printf "\033[92m*** Starting Unbound service ***\033[0m\n"
sudo systemctl start unbound
sudo systemctl enable unbound
#sudo service unbound start