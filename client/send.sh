#!/bin/bash

. /etc/backup/backup.conf

HOSTNAME=`hostname -f`

if [ $TAR_ARCHIVE ]; then
	FILENAME=$TAR_ARCHIVE
else
	FILENAME=$1
fi

if [ $TAR_VOLUME ]; then
	mv $FILENAME $FILENAME-$(echo $TAR_VOLUME - 1 |bc)
	FILENAME=$FILENAME-$(echo $TAR_VOLUME - 1 |bc)
	if [ "$COMPRESSION" == "TRUE" ]; then
		bzip2 $FILENAME
		mv $FILENAME.bz2 $FILENAME.tar.bz2
		FILENAME=$FILENAME.tar.bz2
	else
		mv $FILENAME $FILENAME.tar
		FILENAME=$FILENAME.tar
	fi
	echo "TAR_VOLUME=$TAR_VOLUME" >/tmp/backup-volume.txt
else
	if [ -f "/tmp/backup-volume.txt" ]; then
		. /tmp/backup-volume.txt
	else
		TAR_VOLUME=2
	fi

	mv $FILENAME $FILENAME-$TAR_VOLUME
	FILENAME=$FILENAME-$TAR_VOLUME
	if [ "$COMPRESSION" == "TRUE" ]; then
		bzip2 $FILENAME
		mv $FILENAME.bz2 $FILENAME.tar.bz2
		FILENAME=$FILENAME.tar.bz2
	else
		mv $FILENAME $FILENAME.tar
		FILENAME=$FILENAME.tar
	fi
fi

if [ "$ENCRYPTION" == "TRUE" ]; then
	gpg -e --batch --yes -r $ENCRYPTION_KEY $FILENAME
	if [ $? -eq 0 ]; then
		rm $FILENAME
		FILENAME="$FILENAME.gpg"
	else
		echo "ERROR: Encryption failed"
		curl -F "file=@$RUNLOG" "$URL?hostname=$HOSTNAME&type=error"
		exit
	fi
fi

MD5_BACKUP=`md5sum $FILENAME |awk '{print $1}'`
curl -F "file=@$FILENAME" "$URL?hostname=$HOSTNAME&type=backup&md5=$MD5_BACKUP"
if [ $? -eq 0 ] && [ "$REMOVE_AFTER" == "TRUE" ]; then
	rm $FILENAME
fi
