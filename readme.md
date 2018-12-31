# EasyEngine Tools

A mostly working collection of scripts for managing an [EasyEngine](https://easyengine.io) WordPress hosting server. This is not an official project from EasyEngine and may be renamed in the future.

The backup script creates a full compressed copy of each site to upload to S3. Backups include the site files in the 'htdocs' folder, the MariaDB/MySQL database, the site access log files, the TLS certificates, and an automated full site list restore script.  Daily full site uploads are sent to Amazon S3 in separate well organized folders. This is the opposite of other projects that attempt to create incremental backups. Amazon S3 with Glacier storage is relatively inexpensive. Full site copies along with S3 lifecycle rules offer the storage and retention this project looks to fulfill.

The server setup script is designed to start with a fresh Ubuntu 18.04 vm. It will install EasyEngine v4. Then it will run the cloudflare-ufw script to lock down the server. The backup script will be placed in /etc/cron.daily/ ready to run the next nightly backup. The restore script will be ready with the most recent restorelist ready to restore all websites last backed up to this server by name. This script is designed to quickly bring a server full of WordPress websites back online from nothing but your backups.

We use and recommend Cloudflare. The cloudflare-ufw script only allows HTTP/HTTPS access to the server via CloudFlare which greatly reduces the attack surface. The free Cloudflare tier is more than enough for most WordPress sites. Simply move your [DNS](https://support.cloudflare.com/hc/en-us/articles/201720164-Step-2-Create-a-Cloudflare-account-and-add-a-website) hosting to Cloudflare. Set the A/AAAA/CNAME record to [orange](https://support.cloudflare.com/hc/en-us/articles/200169626-What-subdomains-are-appropriate-for-orange-gray-clouds-). Now your sites pass through Cloudflare protection and you get free [caching](https://support.cloudflare.com/hc/en-us/articles/200172516-Which-file-extensions-does-Cloudflare-cache-for-static-content-)!

### EasyEngine v4 Tools

- Server setup script. Restore an entire server from scratch.
- VPS cloud-init (All secrets needed for setup can be pasted into lauch script box *except GPG)
- Backup htdocs, database & LetsEncrypt certs (compress, encrypt, and upload to Amazon S3)
- Create server rebuild script for disaster recovery (restorelist.sh)
- Restore a site from v3 backup to v4 server
- Restore a site from v4 backup
- Restore all sites from v4 backup restorelist
- CloudFlare UFW IP address whitelist script (completely re-written)

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
- Tested on EasyEngine v3.74 & v4.0.9
- Tested with Ubuntu 18.04 on Amazon LightSail & Amazon S3 for backup storage.
- Use AWS S3 cli. S3cmd is no longer supported. References to s3cmd will be removed in future updates.

## Getting Started

Please use caution. This script is still under development. Some v3 scripts have bucket names/folders hard coded. Development effort is focused on v4 at the moment. Sorry, No support available. Use at your own risk. All scripts are expected to be mostly working at this time. You should be able to backup and restore. Note don't cancel the script while running. EE4 gets corrupted if you mash on Control-C.

### Installing v4

#### New Server

1. Copy the cloud-init file into a text editor of your choice.
2. Edit the email, S3 bucket and AWS access codes as needed.
3. Create a new Ubuntu 18.04 VPS.
4. Paste the cloud-init code into the Launch Script* box.
5. Launch your VPS. Setup time is 3-5 minutes. The server will reboot once if needed.
6. Login via SSH.
7. Run the gpg-private script to finish loading private.key if you included it in your cloud-init
8. If possible, the newest site restorelist will be placed in the /root folder. Run the restorelist-xxxxxxxx.sh to restore all the websites.

 * Tested with Amazon Lightsail Launch Script. Digital Ocean calls this 'User data'. Others should be compatible but they are untested at this time.

#### Existing Server

1. Login via SSH.
2. Clone this repository `git clone https://github.com/microram/ee4-tools.git`
3. Copy the .ee4-backup-settings.conf to /root
4. Edit the .ee4-backup-settings.conf as needed
5. Setup or import a GPG public key. Don't forget to backup this key. You will need the secret private key only for restores.
6. Backup your server with `ee4-backup-sites` manually (run as root. don't forget to `chmox +x ee4-backup-sites`)
7. Place the ee4-backup-sites in /etc/cron.daily to automate

### Installing v3

1. Login via SSH.
2. Clone this repository `git clone https://github.com/microram/ee4-tools.git`
3. Edit the .backup_sites_mysql_s3.conf file first. 
4. Then edit and review each script before using. Some scripts still have hard coded folders at this time.
5. Edit and test the ee4-backup-sites script. Then place in your /etc/cron.daily/ folder.

### Restore Usage Examples

#### Restore v4 site

    ./ee4-restore-site --domain=example.com --type=wp --cache --ssl=self
    ./ee4-restore-site --domain=example2.com --type=wp --cache --ssl=le --admin-email=admin@example2.com

#### Restore v3 site to v4 server

    ./ee4-restore-from-v3-site example.com --type=wp --cache --ssl=self
    ./ee4-restore-from-v3-site example2.com --type=wp --cache --ssl=le --admin-email=admin@example2.com

#### Restore v3 site

    ./v3/wp-restore-site.sh example.com --wpfc

### Coming soon

- [ ] Backup restorelist type is hard coded at --type=wp. Coming soon --type=html and --type=php logic.
- [x] --s3_server_name=server1 handling. This will allow cross server backup & restore. For example backup example1.com on server1, then restore example1.com on server2. Since EE v4 only supports 25 sites max, this should let us move sites around to load balance small VPSs better.  
- [ ] Certificates are not yet being restored. This should not be an issue yet unless you are restoring large numbers of sites and hitting the LetsEncrypt API limit.
- [x] Server startup script needs work at the bottom. Maybe pulling the remaining scripts from github now that they no longer have any hard coded paths.
- [x] Easy setup from scratch
- [x] cloud-init style launch script for your secrets
- [x] GPG public key in cloud-init
- [ ] All scripts needs standardization cleanup
- [ ] Possible reorganization of v3 scripts
- [ ] Restore a site n days prior
- [ ] Restore a glacier backup (low priority. Keep more hot backups see S3 lifecycle rules)
- [x] Fix --ssl=self minor issue `tar: conf.d/example.com-*.conf: Warning: Cannot stat: No such file or directory`
- [ ] ee site info does not distinguish between SSL LE or SELF
- [ ] ee site info appears to report wildcard enabled on SSL SELF
- [ ] graceful exit if incorrect GPG password is typed

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
