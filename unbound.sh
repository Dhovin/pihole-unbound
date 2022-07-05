sudo apt update
sudo apt install -y build-essential libssl-dev libexpat1-dev bison flex doxygen
sudo groupadd -g 88 unbound
sudo useradd -c "Unbound DNS Resolver" -d /var/lib/unbound -u 88 -g unbound -s /bin/false unbound
wget https://nlnetlabs.nl/downloads/unbound/unbound-latest.tar.gz
mkdir ~/unbound
tar xzf unbound-latest.tar.gz -C ~/unbound
cd unbound/
dir=$(ls)
cd $dir
sudo ./configure --prefix=/usr --sysconfdir=/etc --disable-static --with-pidfile=/run/unbound.pid
sudo make
sudo make doc
sudo make install
sudo install -v -m755 -d /usr/share/doc/unbound-1.16.0
sudo install -v -m644 doc/html/* /usr/share/doc/unbound-1.16.0