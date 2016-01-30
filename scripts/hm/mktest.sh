#! /bin/bash
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
	cp "$APSDIR"/template.pdf ./DOCS/"$FILE".pdf
done
	
