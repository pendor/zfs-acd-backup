#!/bin/bash

if [ -z "$2" ] ; then
	echo "Usage: $0 [--acdroot <path>] <dest_zfs> <full_original_snap_name>"
	echo "IE: $0 tank/restore dozer/Original@snap-1234123"
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

NEW=$1
SNAP=$2
#"beastie/Backup/APeX@autosnap_2015-12-24_00:01:01_daily"

if ! zfs list "$NEW" >/dev/null 2>&1 ; then
	echo "Destination zfs $NEW doesn't exist"
	exit 2
fi

acdcli sync  >/dev/null

DNAME=${SNAP//[^0-9A-Za-z_-]/_}
COUNT=`acdcli ls ${DEST} | grep -c "${DNAME}"`
SIZE=`acdcli ls -l -b ${DEST} | grep "${DNAME}" | awk '{print $3}' | paste -sd+ - | bc`
PARTS=`acdcli ls ${DEST} | grep "${DNAME}" | awk '{print $3}' | sort`

echo "Receiving & decoding $SIZE bytes in $COUNT chunks into $NEW..."

{ 
for p in $PARTS ; do
	acdcli cat ${DEST}/$p
done
} | pv -s $SIZE | openssl enc -d -z -aes-256-ctr | zfs receive -v -d $NEW

echo "Restore completed:"
zfs list -r $NEW
