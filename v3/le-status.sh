#!/bin/bash

for dir in /etc/letsencrypt/live/*/
do
    dir=${dir%*/}
    printf '%s: %s\n' \
      "$(date --date="$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/${dir##*/}/cert.pem"|cut -d= -f 2)" --iso-8601)" \
      "${dir##*/}"
done
