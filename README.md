# pihole-unbound

## Supported and tested OS

 * Ubuntu Server 20.04 LTS working
 * Ubuntu Server 22.04 LTS not scripted
 
## Install
 
 wget https://raw.githubusercontent.com/Dhovin/pihole-unbound/main/script.sh -O script.sh && sudo chmod +x script.sh && ./script.sh

## 22.04 LTS Issues
 * full upgrade prompts for outdated service restart during intial and during pihole update
 * netplan gateway4 command deprecated, use default routes
 
### troubleshooting commands
 * systemctl status unbound.service
 * journalctl -xe
