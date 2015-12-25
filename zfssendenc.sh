#!/bin/bash

if [ -z "$1" ] ; then
	echo "Usage: $0 [--acdroot <path>] <full_original_snap_name>"
	echo "IE: $0 tank/Original@snap-1234123"
	echo "Optional: --acdroot : path in ACD to read snaps from"
	echo "              ^^ Either path starting with / or node id"
	echo " "
	exit 1
fi

if [ "$1" == "--acdroot" ] ; then
	shift
	DEST=$1
	shift
else
	DEST=/zfs
fi

SNAP=$1
#SNAP="beastie/Backup/APeX@autosnap_2015-12-24_00:01:01_daily"
CHUNK=1000000000
DNAME=${SNAP//[^0-9A-Za-z_-]/_}

if ! zfs list -H "$SNAP" >/dev/null 2>&1 ; then
	echo "Snapshot $SNAP not found"
	exit 2
fi

acdcli sync  >/dev/null

if acdcli ls "$DEST" | awk '{print $3}' | grep "$DNAME" >/dev/null 2>&1 ; then
	echo "ACD path $DEST already contains snap files for $SNAP."
	echo "Manually delete the files or choose a different path (--acdroot)."
	echo
	acdcli ls "$DEST" | grep "$DNAME"
	exit 3
fi

SIZE=`zfs list -t all -H -p | grep $SNAP | awk '{print $4}'`

echo "Encoding & sending $SIZE bytes from $SNAP..."
zfs send $SNAP | \
	openssl enc -e -z -aes-256-ctr | \
	split --additional-suffix=.zfs.aes --numeric-suffixes --bytes=$CHUNK \
	--filter="acdcli stream -o \$FILE ${DEST}" \
	- ${DNAME}-	
	
acdcli sync >/dev/null

echo "Upload complete.  Created:"
acdcli ls -l "$DEST" | grep "$DNAME"

