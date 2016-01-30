#! /bin/bash
#################################################################################
# Copyright (C) Steven M. Japalucci - All Rights Reserved
# Unauthorized copying of this file, via any medium is strictly prohibited
# Proprietary and confidential
# Written by Steven M Japalucci RHCE RHCT <steve.japalucci@gmail.com>, August 2013
#################################################################################
source /usr/local/bin/aps/conf/config.sh

if [ -z "$1" ]; then
	echo "$0: $0 runsheet"
	exit
fi

mkdir ./DOCS

OLDIFS=$IFS
IFS=$'\n'

for FILE in `./getindex.pl $1`
do
	FILE=`echo "$FILE" | awk 'BEGIN { FS = "%%" } ; { print $2 }'`
	cp "$APSDIR"/template.pdf ./DOCS/"$FILE".pdf
done
	
