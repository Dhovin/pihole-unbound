# pihole-unbound

 * Ubuntu Server 18.04 LTS not working
 * Ubuntu Server 20.04 LTS working
 * Ubuntu Server 22.04 LTS not supported
 
## Install
 
 curl -L https://raw.githubusercontent.com/Dhovin/pihole-unbound/main/script.sh | bash
 
 or
 
 wget https://raw.githubusercontent.com/Dhovin/pihole-unbound/main/script.sh -O script.sh && sudo chmod +x script.sh && ./script.sh

## 18.04 LTS Issues
 * netplan set option not implimented yet
 * unbound service restart failed
 * no prompt for input data
 * 

## 22.04 LTS Issues
 * pihole not supported in 22.04 LTS yet
 * full upgrade prompts for outdated service restart during intial and during pihole update
 * netplan gateway4 command deprecated, use default routes