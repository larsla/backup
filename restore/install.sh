#!/bin/bash
# 
# Written by Lars Larsson <lars@lars.la>
#


if [ $(id -u) != 0 ]; then
	echo "ERROR: You need to be root to run this"
	exit
fi

if [ ! -d /usr/local/share/backup ]; then
	mkdir -p /usr/local/share/backup/
fi
cp switchtape.sh /usr/local/share/backup/
cp backup_listfiles /usr/local/bin/
cp backup_restore /usr/local/bin/

echo "Installation complete" 
