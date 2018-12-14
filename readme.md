# Project Title

A mostly working collection of scripts for managing an [EasyEngine](https://easyengine.io) WordPress hosting server

The backup scripts compress each site htdocs folder and database. Full copies are uploaded to Amazon S3 buckets. Place the script in cron.daily for automated backups.  

### EasyEngine v4 Tools

- Server setup script (Ubuntu 18.04)
- Restore from v3 backup (v4 Coming)
- Backup (Compress, Encrypt, and copy to S3)

### EasyEngine v3 Tools

- Backup all EasyEngine sites to S3
- Backup all MySQL databases to S3 (EasyEngine not required)
- Restore a single WordPress site from S3
- Create a full server restore list with EasyEngine parapmeters (ex. --wp)
- CloudFlare UFW IP address whitelist script
- Create an uncolorized EasyEngine site list
- Fix the ownership (chown) of files based on the parent folder 
- LetsEncrypt Delete, Renew and Status scripts
- Check the WordPress version on all sites
- Update the WordPress version on all sites suitable for cron

## Getting Started

Please use caution, some bucket names/folders are still hard coded. 

No support available. Use at your own risk.

The ee4-restore-site script only restores from v3 backups. This is currently being used for v3 to v4 migration. A v4 restore script will be added soon.

### Prerequisites

Tested with Ubuntu 18.04 on Amazon LightSail & Amazon S3 for backup storage.

S3cmd is no longer supported. Use AWS S3 cli. 

### Installing

Edit the .backup_sites_mysql_s3.conf & .ee4-backup-settings.conf files first. Then edit and review each script before using. Some scripts still have hard coded folders at this time. 

Then run ee4-server-setup on your fresh Ubuntu 18.04 VPS.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
