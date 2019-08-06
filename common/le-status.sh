#!/bin/bash

## Outputs a list of web sites and their LetsEncrypt expiration date
## Example ./le-status.sh
## Output
## 20190101: example.com

## Can be sorted by date
## Example2 ./le-status.sh | sort

for dir in /etc/letsencrypt/live/*/
do
    dir=${dir%*/}
    printf '%s: %s\n' \
      "$(date --date="$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/${dir##*/}/cert.pem"|cut -d= -f 2)" --iso-8601)" \
      "${dir##*/}"
done
