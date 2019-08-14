#!/bin/bash

## Use from within htdocs/
## Example  cd /var/www/example.com/htdocs && ~/fixown.sh

## Change owner to same as current level aka ./
chown -R `stat . -c %u:%g` *
## Force non-customer folder back to root:root
chown root:root stats
find . -type f -exec chmod 754 {} \;
find . -type d -exec chmod 775 {} \;

