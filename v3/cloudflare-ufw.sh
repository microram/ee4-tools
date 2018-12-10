#!/bin/sh -x

DIR="$(dirname $(readlink -f $0))"
cd $DIR
wget https://www.cloudflare.com/ips-v4 -O ips-v4.tmp
wget https://www.cloudflare.com/ips-v6 -O ips-v6.tmp
wget https://uptimerobot.com/inc/files/ips/IPv4.txt -O ips-ur.tmp

# Clean up file names for completed files
mv ips-v4.tmp ips-v4
mv ips-v6.tmp ips-v6

# Adjust uptimerobot ips to linux line endings
tr -d '\015' <ips-ur.tmp >ips-ur

# Add limited ssh access. Control also from AWS Lightsail master firewall
ufw limit ssh

# Add IPv4 rules ufw allow from 8.8.8.8 to any port 80,443 proto tcp
for cfip in `cat ips-v4`; do ufw allow from $cfip to any port 80,443 proto tcp; done

# Disable IPv6
#for cfip in `cat ips-v6`; do ufw allow from $cfip to any port 80,443 proto tcp; done

# Add UptimeRobot rules
for cfip in `cat ips-ur`; do ufw allow from $cfip to any port 80,443 proto tcp; done

ufw reload > /dev/null

rm ips-v4
rm ips-v6
rm ips-ur

# OTHER EXAMPLE RULES
# Examples to retrict to port 80
#for cfip in `cat ips-v4`; do ufw allow from $cfip to any port 80 proto tcp; done
#for cfip in `cat ips-v6`; do ufw allow from $cfip to any port 80 proto tcp; done

# Examples to restrict to port 443
#for cfip in `cat ips-v4`; do ufw allow from $cfip to any port 443 proto tcp; done
#for cfip in `cat ips-v6`; do ufw allow from $cfip to any port 443 proto tcp; done
