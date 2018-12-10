#!/bin/bash

if [ "$#" -ne 1 ]
then
  echo "Usage: le-delete example.com"
  exit 1
fi

echo "Performing backup on /etc/letsencrypt" 
sudo tar -czf /tmp/letsencrypt-`date +%Y%m%d%H%M%S`.tgz /etc/letsencrypt/ 

read -p "Delete Certificate $1 ? " -n 1 -r
printf "\n"
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo "Deleting /etc/letsencrypt/ $1"
  rm -rf /etc/letsencrypt/live/$1
  rm -rf /etc/letsencrypt/renewal/$1.conf
  rm -rf /etc/letsencrypt/archive/$1
fi
