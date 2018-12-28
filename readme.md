# ee4-tools

A mostly working collection of scripts for managing an [EasyEngine](https://easyengine.io) WordPress hosting server. This is not an official project from EasyEngine and may be renamed in the future. 

The backup script creates a full compressed copy of each site to upload to S3. Backups include the site files in the 'htdocs' folder, the MariaDB/MySQL database, the site access log files, the TLS certificates, and an automated full site list restore script that are uploaded in separate well organized folders. Daily full uploads are the opposite of other projects that attempt to create incremental backups. Glacier storage is inexpensive and nicely immutable. Full site copies along with S3 lifecycle rules offer the storage and retention this project looks to fulfill. Place the ee4-backup-sites v4 script (or backup_sites_s3 & backup_mysql_s3 v3 scripts) in /etc/cron.daily/ for automated backups after your testing.

### EasyEngine v4 Tools

- Server setup script (Ubuntu 18.04)
- Restore from v3 backup to v4 server
- Restore from v4 backup (Now working. See usage notes below)
- Backup htdocs, database & LetsEncrypt certs (compress, encrypt, and upload to Amazon S3)
- Create server rebuild script for disaster recovery (restorelist.sh)

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
- [WordOps](https://wordops.org/) the v3 EasyEngine fork project may be supported in the future

## Getting Started

Please use caution. This script is still under development. Some v3 scripts have bucket names/folders hard coded. Development effort is focused on v4 at the moment.  

No support available. Use at your own risk.

All scripts are expected to be mostly working at this time. You should be able to backup and restore.

The ee4-restore-site script is now working. More work is needed on better handling of command line options. 

#### Usage Examples

    ./ee4-restore-site example.com --type=wp --cache --ssl=self
    ./ee4-restore-site example2.com --type=wp --cache --ssl=le --admin-email=admin@example2.com

#### Coming soon

--s3_server_name=server1 handling. This will allow cross server backup & restore. For example backup example1.com on server1, then restore example1.com on server2. Since EE v4 only supports 25 sites max, this should let us move sites around to load balance small VPSs better.  

#### Coming later 

- Certificates are not yet being restored. This should not be an issue yet unless you are restoring large numbers of sites and hitting the LetsEncrypt API limit.  
- Server startup script needs work at the bottom. Maybe pulling the remaining scripts from github now that they no longer have any hard coded paths. 
- More fit & finish with easier setup from scratch. 
- Maybe cloud-init for even more automation https://help.ubuntu.com/community/CloudInit

### Prerequisites

[EasyEngine](https://easyengine.io) v3 or v4

Tested on EasyEngine v4.0.8

Tested with Ubuntu 18.04 on Amazon LightSail & Amazon S3 for backup storage.

Use AWS S3 cli. S3cmd is no longer supported. References to s3cmd will be removed in future updates.

### Installing

Edit the .backup_sites_mysql_s3.conf & .ee4-backup-settings.conf files first. Then edit and review each script before using. Some scripts still have hard coded folders at this time. 

Then run ee4-server-setup on your fresh Ubuntu 18.04 VPS.

Setup a GPG key. 

Edit and test the ee4-backup-sites script. Then place in your /etc/cron.daily/ folder. 

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
