A mostly working collection of scripts for managing an [EasyEngine](https://easyengine.io) WordPress hosting server. This is not an official project from EasyEngine and may be renamed in the future. 

The backup script creates a full compressed copy of each site to upload to S3. Backups include the site files in the 'htdocs' folder, the MariaDB/MySQL database, the site access log files, the TLS certificates, and an automated full site list restore script.  Daily full site uploads are sent to Amazon S3 in separate well organized folders. This is the opposite of other projects that attempt to create incremental backups. Amazon S3 with Glacier storage is relatively inexpensive. Full site copies along with S3 lifecycle rules offer the storage and retention this project looks to fulfill.

### EasyEngine v4 Tools

- Server setup script (Ubuntu 18.04)
- VPS cloud-init (All secrets needed for setup can be pasted into lauch script box *except GPG)
- Restore from v3 backup to v4 server
- Restore from v4 backup (Now working. See usage notes below)
- Backup htdocs, database & LetsEncrypt certs (compress, encrypt, and upload to Amazon S3)
- Create server rebuild script for disaster recovery (restorelist.sh)
- CloudFlare UFW IP address whitelist script completely re-written

### EasyEngine v3 Tools

- Backup all EasyEngine sites to S3
- Backup all MySQL databases to S3 (EasyEngine not required)
- Restore a single WordPress site from S3
- Create a full server restore list with EasyEngine parapmeters (ex. --wp)
- Create an uncolorized EasyEngine site list
- Fix the ownership (chown) of files based on the parent folder
- LetsEncrypt Delete, Renew and Status scripts
- Check the WordPress version on all sites
- Update the WordPress version on all sites suitable for cron
- [WordOps](https://wordops.org/) the v3 EasyEngine fork project may be supported in the future

### Prerequisites

- [EasyEngine](https://easyengine.io) v3 or v4
- Tested on EasyEngine v4.0.9
- Tested with Ubuntu 18.04 on Amazon LightSail & Amazon S3 for backup storage.
- Use AWS S3 cli. S3cmd is no longer supported. References to s3cmd will be removed in future updates.

## Getting Started

Please use caution. This script is still under development. Some v3 scripts have bucket names/folders hard coded. Development effort is focused on v4 at the moment. Sorry, No support available. Use at your own risk. All scripts are expected to be mostly working at this time. You should be able to backup and restore.

### Installing v4

#### New Server

1. Copy the cloud-init file into a text editor of your choice.
2. Edit the email, S3 bucket and AWS access codes as needed.
3. Create a new Ubuntu 18.04 VPS.
4. Paste the cloud-init code into the Launch Script* box.
5. Launch your VPS. Setup time is 3-5 minutes. The server will reboot once if needed.
6. Login via SSH.
7. If possibe, the newest site restorelist will be placed in the root folder. Run the restorelist-xxxxxxxx.sh to restore all the websites.

* Tested with Amazon Lightsail Launch Script. Digital Ocean calls this 'User data'. Others should be compatible. Untested at this time.

#### Existing Server

1. Login via SSH.
2. Clone this repository `git clone https://github.com/microram/ee4-tools.git`
3. Copy the .ee4-backup-settings.conf to /root
4. Edit the .ee4-backup-settings.conf as needed
5. Backup your server with ee4-backup-sites manually (run as root. don't forget to `chmox +x ee4-backup-sites`)
6. Place the ee4-backup-sites in /etc/cron.daily to automate

### Installing v3

Edit the .backup_sites_mysql_s3.conf file first. Then edit and review each script before using. Some scripts still have hard coded folders at this time.

Setup or import a GPG public key. Don't forget to backup this key. You will need the secret private key only for restores.

Edit and test the ee4-backup-sites script. Then place in your /etc/cron.daily/ folder. 

#### Restore Usage Examples

    ./ee4-restore-site --domain=example.com --type=wp --cache --ssl=self
    ./ee4-restore-site --domain=example2.com --type=wp --cache --ssl=le --admin-email=admin@example2.com

#### Coming soon

- [x] --s3_server_name=server1 handling. This will allow cross server backup & restore. For example backup example1.com on server1, then restore example1.com on server2. Since EE v4 only supports 25 sites max, this should let us move sites around to load balance small VPSs better.  
- [ ] Certificates are not yet being restored. This should not be an issue yet unless you are restoring large numbers of sites and hitting the LetsEncrypt API limit.
- [x] Server startup script needs work at the bottom. Maybe pulling the remaining scripts from github now that they no longer have any hard coded paths.
- [x] easier setup from scratch.
- [x] Maybe cloud-init for even more automation https://help.ubuntu.com/community/CloudInit
- [ ] GPG credentials in cloud-init
- [ ] All scripts needs standardization cleanup
- [ ] Possible reorganization of v3 to v4 scripts

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
