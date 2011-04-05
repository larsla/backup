#!/bin/bash
# 
# Written by Lars Larsson <lars.la@gmail.com>
#

. /etc/backup/backup.conf


HOSTNAME=`hostname -f`
DATE=`date +%Y-%m-%d-%s`
FILENAME="backup-$HOSTNAME-$DATE"
TARLOG="/tmp/backup-$HOSTNAME-$DATE.tar.log"

if [ "$ENCRYPTION" == "TRUE" ]; then
	if [ ! `gpg --list-keys |grep $ENCRYPTION_KEY |awk '{print $1}'` ]; then
		if [ -f $ENCRYPTION_KEYFILE ]; then
			gpg --batch --yes --import $ENCRYPTION_KEYFILE
		else
			echo "ERROR: No public key in $ENCRYPTION_KEYFILE"
			curl -F "file=@$RUNLOG" "$URL?hostname=$HOSTNAME&type=error"
			exit
		fi
	fi
fi

# We run a full backup every friday
if [ `date +%u` -eq 5 ]; then
	mv $INCREMENTAL $INCREMENTAL.old
	rm $BACKUPDIR/*.tar.bz2
fi

if [ ! -f $FILES_FROM ]; then
	echo "ERROR: No FILES_FROM file: $FILES_FROM"
	exit
fi
if [ ! -f $EXCLUDES_FROM ]; then
	echo "ERROR: No EXCLUDES_FROM file: $EXCLUDES_FROM"
	exit
else
	EXCLUDES=""
	for EXCL in $(cat $EXCLUDES_FROM); do
		EXCLUDES="$EXCLUDES --exclude=$EXCL"
	done
fi

tar -T $FILES_FROM $EXCLUDES -g $INCREMENTAL --preserve-permissions -M -L 102400 -F /etc/backup/send.sh -cvf $BACKUPDIR/$FILENAME 1>$TARLOG 2>&1
/etc/backup/send.sh $BACKUPDIR/$FILENAME

MD5_LOG=`md5sum $TARLOG |awk '{print $1}'`
curl -F "file=@$TARLOG" "$URL?hostname=$HOSTNAME&type=tarlog&md5=$MD5_LOG"
if [ $? -eq 0 ] && [ "$REMOVE_AFTER" == "TRUE" ]; then
        rm $TARLOG
fi

MD5_INC=`md5sum $INCREMENTAL |awk '{print $1}'`
curl -F "file=@$INCREMENTAL" "$URL?hostname=$HOSTNAME&type=incremental&md5=$MD5_INC"

if [ -f "$RUNLOG" ]; then
	curl -F "file=@$RUNLOG" "$URL?hostname=$HOSTNAME&type=log"
else
	echo "ERROR: No runlog $RUNLOG"
	exit
fi
