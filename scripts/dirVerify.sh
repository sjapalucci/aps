#! /bin/bash
#################################################################################
# Written by Steven M Japalucci <steve.japalucci@gmail.com>, August 2013
#################################################################################

#Get globals from APS config
source /usr/local/bin/aps/conf/config.sh

#Get the directory name to verify
if [ "$1" == "" ]; then
	echo ""$0": Usage "$0" dirname"
	exit 1
else 
	DIRNAME="$1"
fi

#Check to see if DropBox knows what the directory is
$APSDIR/scripts/dropbox_uploader.sh -f $APSDIR/scripts/.dropbox_uploader list "$DIRNAME" &>/dev/null
if [ $? -ne 0 ]; then
	echo ""$0": Directory check failed"
	exit 1
fi

#Check to see if we have the directory locally
if [ ! -d "$DBOXROOT/$DIRNAME" ]; then
	echo ""$0": $DBOXROOT/$DIRNAME not found!"
	exit 1
fi
		

#Set IFS to read data properly
OLDIFS=$IFS
IFS=$'\n'
#Now loop through the the dropbox_uploader output/Gather the file list, and compare it
x=1
for LINE in `$APSDIR/scripts/dropbox_uploader.sh -f $APSDIR/scripts/.dropbox_uploader list "$DIRNAME"`
do
	if [ $x -ne 1 ]; then 
		#Get the file list from dropbox

		#Only check files, skipt every other type of entry
		TYPE=`echo "$LINE" | awk '{print$1}'`
		#echo -e "Type: is "$TYPE""	

		#If its a file, continue with the verification of filename and size
		if [ "$TYPE" == "[F]" ]; then
			SIZE=`echo "$LINE" | awk '{print$2}'`
			FILENAME=`echo "$LINE" | awk '{for(i=3;i<NF;i++)printf "%s",$i OFS; if (NF) printf "%s",$NF; printf ORS}'`
			
			#Verify that local file exists, if not fail
			if test `ls $DBOXROOT/$DIRNAME/$FILENAME`; then
				#Get the local file information
				LFILENAME=`ls -l $DBOXROOT/$DIRNAME/$FILENAME | awk '{for(i=9;i<NF;i++)printf "%s",$i OFS; if (NF) printf "%s",$NF; printf ORS}' 2>/dev/null`
				BLFILENAME=`basename "$LFILENAME" 2>/dev/null`
				LSIZE=`ls -l $DBOXROOT/$DIRNAME/$FILENAME | awk '{print$5}' 2>/dev/null`
		
				#echo -e "Dropbox: $FILENAME $SIZE"
				#echo -e "Local:   $BLFILENAME $SIZE"
		
				#Now compare the results to ensure that the dropbox directory has finished syncing
				if [ "$BLFILENAME" != "$FILENAME" ] && [ $LSIZE -ne $SIZE ]; then
					echo -e ""$0": No match!\n"
					exit 1
				fi
			else
				echo -e ""$0": No match!\n"
				exit 1
			fi
		fi
	fi
	x=$(($x + 1))
done
echo "good"
exit 0

