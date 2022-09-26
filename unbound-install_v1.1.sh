#!/bin/bash

# Variables
	localsrc="/usr/local/src"
    ub_log="/var/log/unbound"
	ub="unbound-latest"
	opnssl="openssl-3.0.1"
	libmnl="libmnl-1.0.4"
	libnghttp2="nghttp2-1.46.0"

# Download required software
function dwnlsw() {
	ubsrc="https://nlnetlabs.nl/downloads/unbound/$ub.tar.gz"
	opensslsrc="https://www.openssl.org/source/$opnssl.tar.gz"
	libmnlsrc="https://www.netfilter.org/projects/libmnl/files/$libmnl.tar.bz2"
	libnghttp2src="https://github.com/nghttp2/nghttp2/releases/download/v1.46.0/$libnghttp2.tar.bz2"
	wget -P $localsrc $ubsrc $opensslsrc $libmnlsrc $libnghttp2src
}

# Unpack software
function extractsw() {
	tar -xzvf $localsrc/$ub.tar.gz -C $localsrc
	tar -xzvf $localsrc/$opnssl.tar.gz -C $localsrc
	tar -xzvf $localsrc/$libmnl.tar.bz2 -C $localsrc
	tar -xzvf $localsrc/$libnghttp2.tar.bz2 -C $localsrc
}

# Install make, build, and compile software dependencies from repo
function installfromrepo() {
	sudo apt-get install -y auto-apt build-essential automake checkinstall dnsutils libexpat1-dev libmnl-dev libevent-dev libssl-dev libsystemd-dev libhiredis-dev python3 libpython3-dev swig
	sudo update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.7 2
}

# Remove make, build, and compile software dependencies from system
function removefromsys() {
	sudo apt-get purge -y auto-apt build-essential automake checkinstall dnsutils libexpat1-dev libmnl-dev libevent-dev libssl-dev libsystemd-dev libhiredis-dev python3 libpython3-dev swig
	sudo apt-get autoremove
}

# Create the unbound system user and group. Add unbound user to unbound group.
function adduser() {
    sudo groupadd -g 991 unbound
    sudo useradd -r -c "unbound" -u 991 -g unbound -s /bin/false unbound
}

# Compile OpenSSL
function compileopenssl() {
	cd $localsrc/$opnssl ; sudo auto-apt run ./configure ; sudo make ; sudo checkinstall --fstrans=0 --pkgname=OpenSSL --pkgversion=3.0.1 --default
}

# Compile libmnl
function compilelibmnl() {
	cd $localsrc/$libmnl ; sudo auto-apt run ./configure ; make ; sudo checkinstall --fstrans=0 --pkgname=libmnl --pkgversion=1.0.4 --default
}

# Compile libnghttp2
function compilelibnghttp2() {
	cd $localsrc/$libnghttp2 ; sudo auto-apt run ./configure ; make ; sudo checkinstall --fstrans=0 --pkgname=nghttp2 --pkgversion=1.46.0 --default
}

# Compile Unbound
function compileub() {
	cd $localsrc/$ub ; sudo auto-apt run ./configure --prefix=/usr --sysconfdir=/etc --includedir=/usr/include --with-pidfile=/run/unbound.pid --with-username=unbound --with-ssl --with-libexpat=/usr --with-libmnl --with-libevent --with-pthreads --with-libhiredis --with-libnghttp2 --with-pyunbound --with-pythonmodule --enable-cachedb --enable-checking --enable-subnet --enable-ipset --mandir=/usr/share/man --infodir=/usr/share/info  --localstatedir=/var --disable-rpath  --with-rootkey-file=/var/lib/unbound/root.key --with-chroot-dir= --libdir=/usr/lib --enable-systemd ; make
    sudo checkinstall --fstrans=0 --pkgname=unbound --pkgversion=1.14.0 --default
    # cd $localsrc/$ub ; ./configure --prefix=/usr --sysconfdir=/etc --disable-static --with-pidfile=/etc/unbound/unbound.pid --with-username=unbound --with-ssl --with-libexpat=/usr --with-libmnl --with-libevent --with-pthreads --with-libhiredis --with-libnghttp2 --with-pyunbound --with-pythonmodule --enable-cachedb --enable-checking --enable-subnet --enable-ipset ; make; make install
}

# Set directory ownership for /etc/unbound. Create dnssec root key
function ubrk() {
    sudo chown unbound:unbound /etc/unbound
    sudo /usr/sbin/unbound-anchor -a /etc/unbound/root.key -v
}    

# Enable remote control for unbound. Keys are created in the /etc/unbound directory.
function ubrc() {
sudo /usr/sbin/unbound-control-setup
}

# Install systemd service
function ubsystemd() {
    cat > /lib/systemd/system/unbound.service << EOF
Description=Validating, recursive, and caching DNS resolver
Documentation=man:unbound(8)
Requires=network.target
After=network.target
Before=network-online.target nss-lookup.target
Wants=nss-lookup.target
[Install]
WantedBy=multi-user.target
[Service]
ExecStartPre=-/usr/sbin/unbound-anchor -a /etc/unbound/root.key -v
ExecStart=/usr/sbin/unbound -d -v
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=360
EOF
}

# Enable and start Unbound service. Stop and disable resolved service
function ubsystemdser() {
    sudo systemctl daemon-reload
	sudo systemctl stop systemd-resolved.service
	sudo systemctl disable systemd-resolved.service
	sudo systemctl enable unbound.service
	sudo systemctl start unbound.service
}

# Create unbound.conf file, back up /etc/unbound/unbound.conf to unbound.conf.bak for future reference
function ubconf() {
    sudo mv /etc/unbound/unbound.conf /etc/unbound/unbound.conf.bak
    cat > /etc/unbound/unbound.conf << EOF
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
}

# Create /etc/unbound/unbound.conf.d directory and unbound.conf.d/pi-hole.conf file.
function ubpiholeconf() {
    sudo mkdir /etc/unbound/unbound.conf.d
    sudo chown unbound:unbound /etc/unbound/unbound.conf.d
    cat > /etc/unbound/unbound.conf.d/pi-hole.conf << EOF
## Validating, recursive caching DNS
## pihole.conf [unbound.conf]
#
    ## Server section ##
server:
    directory: "/etc/unbound"
    username: "unbound"
    #chroot: "/var/lib/unbound"
    # If no logfile is specified, syslog is used
    # There are 5 levels of log verbosity.
    # Level 0 means no verbosity, only errors
    # Level 1 gives operational information
    # Level 2 gives  detailed operational  information
    # Level 3 gives query level information
    # Level 4 gives  algorithm  level  information
    # Level 5 logs client identification for cache misses
    #logfile: "/etc/unbound/unbound.log"
    pidfile: "/etc/unbound/unbound.pid"
    verbosity: 0
   
    # specify the interfaces to answer queries from by ip-address.  The default
    # is to listen to localhost (127.0.0.1 and ::1).  specify 0.0.0.0 and ::0 to
    # bind to all available interfaces.  specify every interface[@port] on a new
    # 'interface:' labeled line.  The listen interfaces are not changed on
    # reload, only on restart.
    interface: 127.0.0.1

    # port to answer queries from
    port: 5335

    # Enable IPv4, "yes" or "no".
    do-ip4: yes

    # Enable IPv6, "yes" or "no".
    do-ip6: no

    # Enable UDP, "yes" or "no".
    do-udp: yes

    # Enable TCP, "yes" or "no". If TCP is not needed, Unbound is actually
    # quicker to resolve as the functions related to TCP checks are not done.
    # NOTE: you may need tcp enabled to get the DNSSEC results from *.edu domains
    # due to their size.
    do-tcp: yes

    # You want to leave this to no unless you have *native* IPv6. With 6to4 and
    # Terredo tunnels your web browser should favor IPv4 for the same reasons
    prefer-ip6: no

    # Use this only when you downloaded the list of primary root servers!
    # If you use the default dns-root-data package, unbound will find it automatically
    #root-hints: "/var/lib/unbound/root.hints"

    # Will trust glue only if it is within the servers authority.
    # Harden against out of zone rrsets, to avoid spoofing attempts.
    # Hardening queries multiple name servers for the same data to make
    # spoofing significantly harder and does not mandate dnssec.
    harden-glue: yes

    # Require DNSSEC data for trust-anchored zones, if such data is absent, the
    # zone becomes  bogus.  Harden against receiving dnssec-stripped data. If you
    # turn it off, failing to validate dnskey data for a trustanchor will trigger
    # insecure mode for that zone (like without a trustanchor).  Default on,
    # which insists on dnssec data for trust-anchored zones.
    harden-dnssec-stripped: yes

    # the time to live (TTL) value lower bound, in seconds. Default 0.
    # If more than an hour could easily give trouble due to stale data.
    cache-min-ttl: 3600

    # the time to live (TTL) value cap for RRsets and messages in the
    # cache. Items are not cached for longer. In seconds.
    cache-max-ttl: 86400

    # Don't use Capitalization randomization as it known to cause DNSSEC issues sometimes
    # see https://discourse.pi-hole.net/t/unbound-stubby-or-dnscrypt-proxy/9378 for further details
    use-caps-for-id: no

    # Reduce EDNS reassembly buffer size.
    # Suggested by the unbound man page to reduce fragmentation reassembly problems
    edns-buffer-size: 1472

    # the maximum number of hosts that are cached (roundtrip, EDNS, lame).
    infra-cache-numhosts: 50000

    # Perform prefetching of close to expired message cache entries
    # This only applies to domains that have been frequently queried
    prefetch: yes

    # the number of queries that a thread gets to service.
    num-queries-per-thread: 2048

    # One thread should be sufficient, can be increased on beefy machines.
    # 1 disables multi-threading. 1 thread per core for dedicated DNS servers
    num-threads: 4

    ## Unbound Optimization and Speed Tweaks ###
    # the number of slabs to use for cache, must be a power of 2 times the
    # number of num-threads set above. more slabs reduce lock contention, but
    # fragment memory usage.
    msg-cache-slabs: 8
    rrset-cache-slabs: 8
    infra-cache-slabs: 8
    key-cache-slabs: 8

    # Increase the memory size of the cache. Use roughly twice as much rrset cache
    # memory as you use msg cache memory. Due to malloc overhead, the total memory
    # usage is likely to rise to double (or 2.5x) the total cache memory. A plain number in bytes,
    # append 'k', 'm' or 'g' for kilobytes, megabytes or gigabytes (1024*1024 bytes in a megabyte).
    # Default is 4 megabytes
    rrset-cache-size: 64m

    # The message cache size. A plain number in bytes,
    # append 'k', 'm' or 'g' for kilobytes, megabytes or gigabytes (1024*1024 bytes in a megabyte).
    # Default  is 4 megabytes.
    msg-cache-size: 32m

    # buffer size for UDP port 53 incoming (SO_RCVBUF socket option). This sets
    # the kernel buffer larger so that no messages are lost during traffic spikes.
    so-rcvbuf: 1m

    # If nonzero, unwanted replies are not only reported in statistics, but also
    # a running total is kept per thread. If it reaches the threshold, a warning
    # is printed and a defensive action is taken, the cache is cleared to flush
    # potential poison out of it.  A suggested value is 10000000, the default is
    # 0 (turned off). We think 10K is a good value.
    unwanted-reply-threshold: 10000

    ## Privacy section ##
    # Ensure privacy of local IP ranges
    private-address: 192.168.0.0/16
    private-address: 169.254.0.0/16
    private-address: 172.16.0.0/12
    private-address: 10.0.0.0/8
    #private-address: fd00::/8
    #private-address: fe80::/10

    # Allow the domain (and its subdomains) to contain private addresses.
    # local-data statements are allowed to contain private addresses too.
    private-domain: "local.theama.co"

    # Ignore chain of trust. Domain is treated as insecure.
    # domain-insecure: "example.com"
    domain-insecure: "local.theama.co"

    # Enable DNS over TLS (DoT)
    # TLS cert bundle
    tls-cert-bundle: /etc/ssl/certs/ca-certificates.crt

    # If you have an internal or private DNS names the external DNS servers can
    # not resolve, then you can assign domain name strings to be redirected to a
    # seperate dns server. For example, our comapny has the domain
    # organization.com and the domain name internal.organization.com can not be
    # resolved by Google's public DNS, but can be resolved by our private DNS
    # server located at 1.1.1.1. The following tells Unbound that any
    # organization.com domain, i.e. *.organization.com, can be dns resolved by 1.1.1.1
    # instead of the public dns servers.
    # forward-zone:
    #    name: "organization.com"
    #    forward-addr: x.x.x.x        # Internal or private DNS
    # Connect to Cloudflare
    forward-zone:
    name: "."
    forward-tls-upstream: yes
    # Cloudflare DNS IPv4 DoT
    forward-addr: 1.1.1.1@853#cloudflare-dns.com
    forward-addr: 1.0.0.1@853#cloudflare-dns.com

    ## Remote control section ##
remote-control:
    # Enable remote control with unbound-control(8) here.
    control-enable: yes

    # Give IPv4 or IPv6 addresses or local socket path to listen on  for
    # control  commands.   By  default  localhost (127.0.0.1 and ::1) is
    # listened to.  Use 0.0.0.0 and ::0 to listen to all interfaces.  If
    # you  change  this  and  permissions  have  been  dropped, you must
    # restart the server for the change to take effect.
    #control-interface: 0.0.0.0

    # port number for remote control operations. Default is 8953
    #control-port: 8953

    # unbound control files
    server-key-file: "/etc/unbound/unbound_server.key"
    server-cert-file: "/etc/unbound/unbound_server.pem"
    control-key-file: "/etc/unbound/unbound_control.key"
    control-cert-file: "/etc/unbound/unbound_control.pem"
#
## Validating, recursive caching DNS
## pihole.conf [unbound.conf]
EOF
    sudo chown unbound:unbound /etc/unbound/unbound.conf
    sudo chmod -R 755 /etc/unbound/
    # Creating handy symlink to /etc/unbound/unbound/conf.d/pi-hole.conf file from home directory
    ln -s /etc/unbound/unbound.conf.d/pi-hole.conf ~/pi-hole.conf
}

# Create logfile
function ublogfile() {
	touch /var/log/unbound/unbound.log
	chown unbound:unbound /var/log/unbound/unbound.log
}

# Setup function. Runs the above functions
function setup() {
	dwnlsw
    ublogfile
	extractsw | tee $ub_log/untar_software.log
	installfromrepo | tee $ub_log/install_dependencies.log
	compileopenssl | tee $ub_log/compile_openssl.log
	compilelibmnl | tee $ub_log/compile_limnl.log
	compilelibnghttp2 | tee $ub_log/compile_libnghttp2.log
	adduser
	compileub | tee $ub_log/compile_unbound.log
	ubsystemd
    ubrk
    ubrc
    ubconf
    ubpiholeconf
    ubsystemdser
	echo ""
	echo "logs can be found in $ub_log!!"
	echo ""
}

# Run setup function
if [ $(whoami) != "root" ]; then
		echo "please run as root"
	else
		setup
        # Prompt user to keep or remove installation, build, and compile dependencies
        while true; do
        read -r -p "Unbound installed and configured. Do you wish to remove install, build, and compile dependencies from the system? (Y/N): " answer
        case $answer in
        [Yy]* ) echo "Removing...";
                removefromsys
                echo "Compile, build, and install dependencies removed from system. Unbound installed successfully."; break;;
        [Nn]* ) echo "Unbound installed successfully."; exit;;
        * ) echo "Please answer Y or N.";;
        esac
    done
fi

# Exit with success
exit=0