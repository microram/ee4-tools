#!/bin/bash
#
#  Website S3 RESTORE from EasyEngine3 to EasyEngine4
#
# Params:
#        $1 = domain name (example.com)
#        $2 = site type --type=wp | --type=php
#        $3 = redis cache --cache
# 	 $4 = letsencrypt --ssl=le
# 	 $5 = letsencrypt email --le-mail=webmaster@example.com

function main {

	# Load configuration

    if [[ -r ~/.backup_sites_mysql_s3.conf ]] ; then
        . ~/.backup_sites_mysql_s3.conf
    else
        echo "ERROR - Settings file not found or not readable."; exit 1
    fi

    # Globals
    tmp=/tmp
	domain=$1

	# Check site exists and delete
	if [ -d "/opt/easyengine/sites/$domain" ]; then
		echo delete $domain
	    	ee site delete $domain --yes
	fi

	# Create the site
	echo Create $domain
	ee site create $domain $2 $3 $4 $5 $6

	# Restore the site
	echo Restoring $domain from S3
	restore_wp_domain_s3

	# Restore the database if specified
	if [ -n "$2" ]; then
	        db_user=`ee site info $domain | grep 'DB User' | awk -F '|' '{print $3}' | awk '{print $1}'`
        	db_password=`ee site info $domain | grep 'DB Password' | awk -F '|' '{print $3}' | awk '{print $1}'`
        	db_host=`ee site info $domain | grep 'DB Host' | awk -F '|' '{print $3}' | awk '{print $1}'`
        	db_name=`ee site info $domain | grep 'DB Name' | awk -F '|' '{print $3}' | awk '{print $1}'`
		echo Restoring database for $domain
		restore_db_s3
	fi

	## Install any new plugins
	#ee shell $domain --command="wp plugin install https://downloads.wordpress.org/plugin/machete.zip --force --activate"


	## Enable the admin tools
	echo Enabling admin tools for $domain
	ee admin-tools enable $domain

} #main

function restore_wp_domain_s3 {
	## Clean the site folder
	rm -rf /opt/easyengine/sites/$domain/app/htdocs

	## Determine the newest site backup file
	sitefile=`aws s3 ls s3://$bucket/hosting2/backup/site/$domain/ | awk '{print $4}' | tail -1`
	## Download if needed the site backup file
        if [ ! -f $tmp/$sitefile ]; then
		aws s3 cp s3://$bucket/hosting2/backup/site/$domain/$sitefile $tmp/
	fi
	## Make a temp folder as we only want the htdocs folder from the archive
	mkdir $tmp/temp-$domain
	## Extract the download
	tar xf $tmp/$domain* -C $tmp/temp-$domain/
	## Move only the htdocs folder
	mv $tmp/temp-$domain/htdocs /opt/easyengine/sites/$domain/app/
	## Remove any old wp-config file
	mv /opt/easyengine/sites/$domain/app/htdocs/wp-config.php /opt/easyengine/sites/$domain/app/htdocs/wp-config.php.ee4bak
	## Fix file and folder permissions
	find /opt/easyengine/sites/$domain/app/htdocs/ -type f -exec chmod 644 {} \;
	find /opt/easyengine/sites/$domain/app/htdocs/ -type d -exec chmod 755 {} \;
	rm $tmp/$domain*
	rm -rf $tmp/temp-$domain
}

function restore_db_s3 {
	## Drop all the tables
	ee shell $domain --command="mysqldump -h $db_host -u$db_user -p$db_password --no-data --add-drop-table $db_name | grep ^DROP | mysql -h $db_host -u$db_user -p$db_password $db_name"
	## Lookup the newest database backup
	dbfile=`aws s3 ls s3://$bucket/hosting2/backup/mysql/$db_name/ | awk '{print $4}' | tail -1`
	## Build a filename without the .xz
	dbfile2=${dbfile/.sql.xz/.sql}
	## Download the newest backup
	aws s3 cp s3://$bucket/hosting2/backup/mysql/$db_name/$dbfile /opt/easyengine/sites/$domain/app/
	## Decompress the donwload
	xz -d /opt/easyengine/sites/$domain/app/$dbfile
	## Restore the datbase into the container
	ee shell $domain --command="mysql -h $db_host -u $db_user -p$db_password $db_name < ../$dbfile2"
	rm /opt/easyengine/sites/$domain/app/$dbfile2
}

main "$@"
