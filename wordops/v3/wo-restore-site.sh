#!/bin/bash
#
#  WordOps RESTORE from S3
#
# Params:
#        $1 = domain name (example.com)
#        $2 = site type (null|--mysql|--wp|--redis)
#

function main {
	### Load configuration
	if [[ -r ~/.backup_sites_mysql_s3.conf ]] ; then
		. ~/.backup_sites_mysql_s3.conf
	else
		echo "ERROR - Settings file not found or not readable."; exit 1
	fi

	### Globals
	## Convert non-standard WordPress table_prefix back to wp_
	fixprefix=true
	## Cache site files from S3. Saves S3 cost during testing. DEFAULT false
	cachefiles=true
	## Temp folder
	tmp=/tmp
	## WordOps site type and switch --w3tc & --wpfc to --wpredis
	sitetype=${2/--w3tc/--wpredis}
	sitetype=${sitetype/--wpfc/--wpredis}
	## Site domain name
	domain=$1
	## Database name converted from . to _ notation
	dbtest=${domain/./_}
	dbname=${dbtest/./_}
	## mysql root username and password
	my_user=`grep -i "user" /etc/mysql/conf.d/my.cnf | awk -F\= '{gsub(/"/,"",$2);print $2}' | awk '{print $1}'`
	my_password=`grep -i "password" /etc/mysql/conf.d/my.cnf | awk -F\= '{gsub(/"/,"",$2);print $2}' | awk '{print $1}'`
	## Override config file if restoring from a different server
	mysql_base_folder=hosting2/backup/mysql
	sites_base_folder=hosting2/backup/site

	## Check if site exists then delete
	if [ -d "/var/www/$domain" ]; then
		echo Remove old site $domain
		wo site delete $domain --no-prompt --all --force
		## Clean the caches
		wo clean --all
	fi

	## Create the site
	echo Create site $domain
	wo site create $domain $sitetype


	## Restore the site files
	restore_wp_domain_s3

	## Restore the database if --wp --wpredis --wpfc --mysql 
	if [ "$2" == "--wp" ] || [ "$2" == "--wpredis" ] || [ "$2" == "--pfc" ] || [ "$2" == "--mysql" ]; then
		## Fix non wp_ prefix databases
		wprefix=`cat /var/www/$domain/wp-config.php.old | grep table_prefix | cut -d \' -f 2`
		echo "WordPress table_prefix $wprefix"
		restore_db_s3
	fi

	## Optimize the site DB & Update all plugins
	site_update_optimize

	## Enable LetsEncrypt Certificate
	if [ ! -f /etc/letsencrypt/live/$domain/privkey.pem ] && [ -f /etc/letsencrypt/live/$domain/key.pem ]; then
		cp /etc/letsencrypt/live/$domain/key.pem /etc/letsencrypt/live/$domain/privkey.pem
	fi
	wo site update $domain -le --dns=dns_cf

	echo Site $domain restored.
} #main

function restore_wp_domain_s3 {
	### Preserve new site config
	if [ -f /var/www/$domain/wp-config.php ]; then
		mv /var/www/$domain/wp-config.php /var/www/$domain/wp-config.php.wordops
	fi
	#if [ -f /var/www/$domain/ee-config.php ]; then
	#	### WARNING This may have changed from ee- to wo- needs more testing
	#	mv /var/www/$domain/ee-config.php /var/www/$domain/ee-config.php.wordops
	#fi

	### Download the wordpress site backup file
	sitefile=`aws s3 ls s3://$bucket/$sites_base_folder/$domain/ | awk '{print $4}' | tail -1`
	if [ ! -f $tmp/$sitefile ]; then
		aws s3 cp s3://$bucket/$sites_base_folder/$domain/$sitefile $tmp
	fi

	### Decompress the site files
	tar xf $tmp/$sitefile -C /var/www/$domain/

	### PHP 7 Fixes
	echo Patching PHP 7 issues
	## Change split() to preg_split() https://www.php.net/manual/en/function.split.php
	find /var/www/$domain/ -type f -exec sed -i 's/ split(/ preg_split(/g' {} +

	### Archive old site config
	if [ -f /var/www/$domain/wp-config.php ]; then
		mv /var/www/$domain/wp-config.php /var/www/$domain/wp-config.php.old
		#mv $tmp/wp-config.php /var/www/$domain/
		#ls -lh $tmp/wp-config.php
	fi
	#if [ -f /var/www/ee-config.php ]; then
	#	mv /var/www/$domain/ee-config.php /var/www/$domain/ee-config.php.old
	#	#mv $tmp/ee-config.php /var/www/$domain/
	#fi
	chown -Rf www-data:www-data /var/www/$domain
	if [ ! "$cachefiles" = true ]; then
		rm $tmp/$domain*
	fi
}

function restore_db_s3 {
	### Clear the default WordPress database
	mysqldump -u$my_user -p$my_password --no-data --add-drop-table $dbname | grep ^DROP | mysql -u$my_user -p$my_password $dbname
	dbfile=`aws s3 ls s3://$bucket/$mysql_base_folder/$dbname/ | awk '{print $4}' | tail -1`
	dbfile2=${dbfile/.sql.gz/.sql}
	## Use cached DB file if available
	if [ ! -f $tmp/$dbfile2 ]; then
		aws s3 cp s3://$bucket/$mysql_base_folder/$dbname/$dbfile $tmp
	fi
	## Decompress backup file if needed
	if [ -f $tmp/$dbfile ]; then
		gunzip -f $tmp/$dbfile
	fi

	## Patch the non-standard table_prefix
	if [ "$wprefix" != "wp_" ]; then
		if [ fixprefix ]; then
			## Find/Replace the non-standard table_prefix to wp_
			sed -i "s/$wprefix/wp_/g" $tmp/$dbfile2
		else
			## Keep the non-standard table_prefix
			sed -i "s/wp_/$wprefix/g" /var/www/$domain/wp-config.php.wordops
		fi
	fi

	## Restore new site config
	if [ -f /var/www/$domain/wp-config.php.wordops ]; then
		mv /var/www/$domain/wp-config.php.wordops /var/www/$domain/wp-config.php
	fi

	## mysql restore
	echo Restore $domain database
	mysql -h 127.0.0.1 -u $my_user -p$my_password $dbname < $tmp/$dbfile2
	if [ ! "$cachefiles" = true ]; then
		rm $tmp/$dbfile2
	fi
}

function site_update_optimize {
	#wp config get --allow-root --path=/var/www/$domain/htdocs/
	wp db optimize --allow-root --path=/var/www/$domain/htdocs/
	if [ "$sitetype" == "--wpredis" ]; then
		## remove old cache plugins
		wp plugin deactivate wp-super-cache --allow-root --path=/var/www/$domain/htdocs/
		wp plugin delete wp-super-cache --allow-root --path=/var/www/$domain/htdocs/
		wp plugin deactivate advanced-cache.php --allow-root --path=/var/www/$domain/htdocs/
		wp plugin delete advanced-cache.php --allow-root --path=/var/www/$domain/htdocs/
		## install redis-cache plugin
		wp plugin activate nginx-helper --allow-root --path=/var/www/$domain/htdocs/
		wp plugin activate redis-cache --allow-root --path=/var/www/$domain/htdocs/
	fi
	## Update the plugins
	wp plugin update --all --allow-root --path=/var/www/$domain/htdocs/
	## Install our favorite site offline plugin
	wp plugin install site-is-offline-plugin --allow-root --path=/var/www/$domain/htdocs/
	## Show the remaining plugins
	wp plugin list --allow-root --path=/var/www/$domain/htdocs/
}

main "$@"
