#!/bin/bash -x
#
#  Website RESTORE from S3 EasyEngine
#
# Params:
#        $1 = domain name (example.com)
#        $2 = site type (null|--mysql|--wp|--wpfc|--wptc)
#

function main {

	# Load configuration

    if [[ -r ~/.backup_sites_mysql_s3.conf ]] ; then
        . ~/.backup_sites_mysql_s3.conf
    else
        echo "ERROR - Settings file not found or not readable."; exit 1
    fi

    # Globals
    tmp=/tmp
	sitetype=$2
	domain=$1
	dbtest=${domain/./_}
	dbname=${dbtest/./_}	# replace the . with _ in the domain name for easyengine dbname
	# mysql root username and password
	my_user=`grep -i "user" /etc/mysql/conf.d/my.cnf | awk -F\= '{gsub(/"/,"",$2);print $2}' | awk '{print $1}'`
	my_password=`grep -i "password" /etc/mysql/conf.d/my.cnf | awk -F\= '{gsub(/"/,"",$2);print $2}' | awk '{print $1}'`

	# Check site exists and delete
	if [ -d "/var/www/$domain" ]; then
		echo delete $domain
	    ee site delete $domain --no-prompt
	fi

	# Create the site
	echo Create $domain
	ee site create $domain $sitetype   #--letsencrypt --experimental (requires A/CNAME already setup)


	# Restore the site
	restore_wp_domain_s3

	# Restore the database if specified
	if [ -n "$2" ]; then
		restore_db_s3
	fi

	## Enable LetsEncrypt Certificate
	ee site update $domain -le --experimental

} #main

function restore_wp_domain_s3 {
	# Preserve new site password
	if [ -f /var/www/$domain/wp-config.php ]; then
		mv /var/www/$domain/wp-config.php $tmp
	fi
	if [ -f /var/www/$domain/ee-config.php ]; then
		mv /var/www/$domain/ee-config.php $tmp
	fi
	# Download the wordpress site backup file
	sitefile=`aws s3 ls s3://$bucket/hosting2/backup/site/$domain/ | awk '{print $4}' | tail -1`
	aws s3 cp s3://$bucket/hosting2/backup/site/$domain/$sitefile $tmp
	tar xf $tmp/$domain* -C /var/www/$domain/
 	# Restore new site config
	if [ -f $tmp/wp-config.php ]; then
   		#mv /var/www/$domain/wp-config.php /var/www/$domain/wp-config.php.old
		mv $tmp/wp-config.php /var/www/$domain/
	fi
	if [ -f $tmp/ee-config.php ]; then
   		#mv /var/www/$domain/ee-config.php /var/www/$domain/ee-config.php.old
		mv $tmp/ee-config.php /var/www/$domain/
	fi
	chown -Rf www-data:www-data /var/www/$domain
	rm $tmp/$domain*
}

function restore_db_s3 {
	# Drop all the tables
	mysqldump -u$my_user -p$my_password --no-data --add-drop-table $dbname | grep ^DROP | mysql  -u$my_user -p$my_password $dbname
	dbfile=`aws s3 ls s3://$bucket/hosting2/backup/mysql/$dbname/ | awk '{print $4}' | tail -1`
	dbfile2=${dbfile/.sql.xz/.sql}
	aws s3 cp s3://$bucket/hosting2/backup/mysql/$dbname/$dbfile $tmp
	xz -d $tmp/$dbfile
	# mysql restore
	mysql -h 127.0.0.1 -u $my_user -p$my_password $dbname < $tmp/$dbfile2
	rm $tmp/$dbfile2
}

main "$@"
