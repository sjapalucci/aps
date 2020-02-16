#! /bin/bash
#################################################################################
# Written by Steven M Japalucci <steve.japalucci@gmail.com>, August 2013
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
	
