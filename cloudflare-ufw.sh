#!/bin/sh -x

## Build a UFW whitelist for CloudFlare & UptimeRobot. 
##   ** NO DIRECT 80,443 access to this server ** 
##   You must use CloudFlare with an ORANGE CLOUD in Cloudflare DNS for EVERY website.

# UFW reset rules
ufw --force reset

# UFW allow LIMITed SSH access
ufw limit ssh

# UFW Whitelist Cloudflare IPv4
for ip in `curl https://www.cloudflare.com/ips-v4`; do ufw allow from $ip to any port 80,443 proto tcp; done
# UFW Whitelist Cloudflare IPv6
for ip in `curl https://www.cloudflare.com/ips-v6`; do ufw allow from $ip to any port 80,443 proto tcp; done
# UFW Whitelist UptimeRobot IPv4 (Fix CRLF/LF)
for ip in `curl https://uptimerobot.com/inc/files/ips/IPv4.txt | tr -d '\r'`; do ufw allow from $ip to any port 80,443 proto tcp; done

# ENABLE UFW Firewall
ufw enable
