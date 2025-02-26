# pihole-unbound
***All versions broken since Pihole v6 release***

## Supported and tested OS
 * Raspian Bookworm - mostly working
 * Ubuntu Server 24.04 LTS - not working
 
## Install
 
 wget https://raw.githubusercontent.com/Dhovin/pihole-unbound/main/script.sh -O script.sh && sudo chmod +x script.sh && ./script.sh

## Issues
 * pihole update can change port to 8080 thinking that lighttpd is still installed
 * probably something else
 
### troubleshooting commands
 * systemctl status unbound.service
 * journalctl -xe
