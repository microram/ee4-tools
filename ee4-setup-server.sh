#!/bin/bash
## EASYENGINE.IO Server prep v4 BETA

## Update Ubuntu 18.04
apt-get update 
#apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade -qy 
DEBIAN_FRONTEND=noninteractive
apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade


## Install AWS CLI
apt-get install -y python-pip
pip install awscli

## Check for reboot after apt-get. Python errors in s3cmd need reboot. Does s3cmd install need to be moved up here?
if [[ -f /var/run/reboot-required ]]
then 
	echo "Reboot required before continuing. Please restart this script after reboot."
	reboot
fi

## Set AWS Credentials
mkdir /root/.aws
echo "[default]" > ~/.aws/config
echo "aws_access_key_id=XXXXXXXXXXXXXXX" >> ~/.aws/config
echo "aws_secret_access_key=YYYYYYYYYYYYYYYYYYYYYYYYYYYYY" >> ~/.aws/config

## Ensure the AWSCLI config file exists to restore the data
if [[ ! -f ~/.aws/config ]] 
then 
	echo "Abort. Missing ~/.aws/config file."; exit 1; 
fi

## Defaults to avoid prompt during ee install
echo "[user]" > ~/.gitconfig
echo "name = Hosting Co." >> ~/.gitconfig
echo "email = webmaster@example.com" >> ~/.gitconfig

## Install EasyEngine.io v4 BETA
echo "==> Installing EasyEngine.io"
wget -qO ee rt.cx/ee4 && sudo bash ee  

## Check for reboot after ee install
if [[ -f /var/run/reboot-required ]]
then 
	echo "Reboot required before continuing. Please restart this script after reboot."
	reboot
fi

##UFW

## Get the site settings file
aws s3 cp s3://bucketname/scripts/.backup_sites_mysql_s3.conf ~/
chmod 400 ~/.backup_sites_mysql_s3.conf
if [[ -r ~/.backup_sites_mysql_s3.conf ]] ; then
    . ~/.backup_sites_mysql_s3.conf
else
    echo "ERROR - Settings file not found or not readable."; exit 1
fi


## Get the site deploy script
aws s3 cp s3://$bucket/scripts/ee4-restore-site.sh ~/
chmod +x ee4-restore-site.sh

## Get the backup scripts and settings
#aws s3 cp s3://$bucket/scripts/backup_sites_s3 /etc/cron.daily/
#chmod +x /etc/cron.daily/backup_sites_s3
#aws s3 cp s3://$bucket/scripts/backup_mysql_s3 /etc/cron.daily/
#chmod +x /etc/cron.daily/backup_mysql_s3

## Get the list of sites to restore
restorefile=`aws s3 ls s3://$bucket/$config_base_folder/restorelist/ | awk '{print $4}' | tail -1`
aws s3 cp s3://$bucket/$config_base_folder/restorelist/$restorefile ~/
chmod +x ~/$restorefile*

## Get the latest LetsEncrypt certs
#lefile=`aws s3 ls s3://$bucket/$le_base_folder/ | awk '{print $4}' | tail -1`
#aws s3 cp s3://$bucket/$le_base_folder/$lefile $tmp
#tar xf $tmp/$lefile* -C /etc/letsencrypt/

## Finished
#echo "Ready to restore the sites. Run the restorelist next."
