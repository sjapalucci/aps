#! /bin/bash
#################################################################################
# Written by Steven M Japalucci <steve.japalucci@gmail.com>, August 2013
#################################################################################

#This script will read a Run Sheet, split and tag the 
#files in that runsheet with the appropiate names, then will 
#compile those files into one pdf in the order they are in in the 
#Run Sheet, then it calls the writelink.pl script whick hyperlinks 
#The doc in the runsheet

#Global Vars
APSDIR="/usr/local/bin/aps"
OUTDIR="/var/spool/aps"
#We need to custom compile poppler to get the pdfinfo command, so it is stored in /usr/local
PDFINFO="/usr/local/bin/pdfinfo"
PDFTOPS="/usr/local/bin/pdftops"

function usage {
	echo "Usage: $0 -pCvcuw -i In Directory -n Customer name"
	echo "-i Directory of the job to be ran"
	echo "-n Customer name (Where per-customer scripts are located)"
	echo "-p create pdf"
	echo "-u upload to webserver"
	echo "-w write links to runsheet"
	echo "-c clense pdf's"
	echo "-C create Burnable CD folder"
	echo "-v Verbose output"
	exit 1
}

function dropboxCheck() {
	STATUS=5
	while [ $STATUS -ne 0 ]
	do
		
		FILE=$1
                if [ ! -e "$FILE" ]; then
                        echo "$(date) DropBox check indicates that "$FILE": Does not exist!"
                        break
                fi

		#Sleep for inital iteration because Dropbox reports file as "up to date" until it begins the sync
		if [ $STATUS -eq 5 ]; then
			sleep 20
		fi
		
		#Now run the ckeck
		/usr/local/bin/dropbox filestatus "$1" | grep 'up to date' &>/dev/null
		STATUS=$?

		if [ $STATUS -eq 0 ]; then
			break
		else
			echo "$(date) Waiting for DropBox sync to complete" 
			sleep 20
		fi
	done
}
 
#Check for arguments
(( $# )) || usage

while getopts i:n:puwcvC flag; do
  case $flag in
    i)
      INDIR=$OPTARG;
      ;;
    n)
      #Where the per-customer scripts are located
      CSCRIPTDIR=$OPTARG;
      ;;
    u)
      UPLOAD="TRUE";
      ;;
    w)
      WRITE="TRUE";
      ;;
    p)
      PDFCREATE="TRUE";
      ;;
    c)
      CLENSE="TRUE";
      ;;
    C)
      MKCD="TRUE";
      ;;
    v)
      VERBOSE="TRUE";
      ;;
    ?)
      usage
      ;;
  esac
done

#Get the parcelno from the directory name
#--FIXME--Rename to basedir to allow for directory name to be anything it needs to be
PARCEL=`basename $INDIR | sed 's/ //g'`
ERRFILE="$INDIR/$PARCEL-error.html"
touch "$ERRFILE"
chown apache:apache "$ERRFILE"


#Where we put uncessfully processed directories
ERRDIR="`dirname "$INDIR"`/Error"
if [ ! -d "$ERRDIR" ]; then
        mkdir -p "$ERRDIR"
        chown apache:apache "$ERRDIR"
fi

#Check for and define runsheet
if [ ! -f "$INDIR/index.xls" ]; then
        echo "$(date) $INDIR/index.xls Run Sheet not found!<br>" >> $ERRFILE
	mv $INDIR $ERRDIR
        exit 1
else
        RUNSHEET="$INDIR/index.xls"
fi


#Chech the Parcel Number in the Runsheet and verify that it is read
PARCELNO=`"$APSDIR"/scripts/"$CSCRIPTDIR"/getparcel.pl $RUNSHEET`
if [ "$PARCELNO" == "" ]; then
        echo "$(date) Unable to read Parcel Number from the runsheet: Check Row 2 Column K<br>" >> $ERRFILE
	if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) Unable to read Parcel Number from the runsheet: Check Row 2  Column K"; fi
	mv $INDIR $ERRDIR
	dropboxCheck "$ERRDIR/$PARCEL"
	exit 1
fi
	
#Check Usage
if [ -n "$WRITE" ] && [ -z "$RUNSHEET" ]; then
		usage
elif [ -n "$PDFCREATE" ] || [ -n "$UPLOAD" ]; then
	
	#Check if required directories exist
	if [ ! -d "$INDIR" ]; then
		echo "$(date) $INDIR: Directory not found!<br>" >> $ERRFILE
		mv $INDIR $ERRDIR
		dropboxCheck "$ERRDIR/$PARCEL"
		exit 1
	else
		DOCDIR="$INDIR"
	fi
fi

OUTDIR="$OUTDIR/$PARCEL"
if [ ! -d "$OUTDIR" ]; then
	mkdir -p "$OUTDIR"
fi

DONEDIR="$INDIR/Completed"
if [ ! -d "$DONEDIR" ]; then
        mkdir -p "$DONEDIR"
	chown apache:apache "$DONEDIR"
fi

#Where we put sucessfully processed directories
PROCDIR="`dirname "$INDIR"`/Processed"

if [ ! -d "$PROCDIR" ]; then
        mkdir -p "$PROCDIR"
	chown apache:apache "$PROCDIR"
fi

#Start doing stuff!
if [ -n "$PDFCREATE" ]; then
	#Set IFS to read data properly
	OLDIFS=$IFS
	IFS=$'\n'
	DOCNUM=0
	PGCOUNT=1 #Increment the page count for bookmarking
	
	#Check files before running
	if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) ####Attempting to run $PARCELNO"; fi
	
	#Before we check the files, run a command to rename all file extensions to lowercase
	if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) Renaming .pdf files with uppercase in the file extension"; fi
	
	find $DOCDIR -iname "*.pdf" -exec rename  s/\.[pP][dD][fF]/\.pdf/ {} \; 

	#Now verify that every file listed in the runsheet is in the Document Directory
	#If now we error out and write the error to the HTML error file
	for FILE in `"$APSDIR"/scripts/"$CSCRIPTDIR"/getindex.pl $RUNSHEET`
	do
		FILE=`echo "$FILE" | awk 'BEGIN { FS = "%%" } ; { print $2 }'`
		#Check if the pdf file exists
                if [ -f "$DOCDIR/$FILE.pdf" ]
                then
			continue
                else
                        echo "$(date) <b>$FILE.pdf</b>: Not found in $PARCEL<br>" >> $ERRFILE
                        echo "$(date) <b>$FILE.pdf</b>: Not found in $PARCEL<br>"
			ERROR="TRUE"
                fi
	done
	if [ "$ERROR" == "TRUE" ]; then
		mv $INDIR $ERRDIR
		if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) ERROR: Moving "$INDIR" to "$ERRDIR""; fi
		exit 1;
	else
		if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) All files found, continuing..."; fi
	fi

	#Read data from Run Sheet
	for FILE in `"$APSDIR"/scripts/"$CSCRIPTDIR"/getindex.pl $RUNSHEET`
	do
	        ITEMNO=`echo "$FILE" | awk 'BEGIN { FS = "%%" } ; { print $1 }'`
		FILE=`echo "$FILE" | awk 'BEGIN { FS = "%%" } ; { print $2 }'`
	         if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) File: $FILE"; fi
		ITEMNO="Item Number: $ITEMNO"
		
		#Set CDOCDIR
                if [ -f "$DOCDIR/$FILE.pdf" ]
                then
                        CDOCDIR=$DOCDIR
                else
                        echo "$(date) $FILE.pdf: Not found in $DOCDIR" >> $ERRFILE
			mv $INDIR $ERRDIR
                        ERROR="TRUE"
                fi

		#Set tmp file name for easy cleanup
		tmpfile=tmp-delme-$$
		
		#Split and tag the file
		if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) File: $ITEMNO"; fi
		if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) Processing: $FILE.pdf"; fi
		if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) $CDOCDIR/$FILE.pdf"; fi
		
		#First we need to clense the PDF if the option is selected
		if [ -n "$CLENSE" ]; then
			#if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) Converting $CDOCDIR/$FILE.pdf to PS and back"; fi
			$PDFTOPS -level3 -origpagesizes -expand -nocrop -noshrink "$CDOCDIR/$FILE.pdf" "$OUTDIR/$tmpfile-clense.ps"
			ps2pdf "$OUTDIR/$tmpfile-clense.ps" "$CDOCDIR/$FILE.pdf"
			rm -f "$OUTDIR/$tmpfile-clense.ps"
		fi
		
		#Get the number of pages in the PDF
			#if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) Converting: $CDOCDIR/$FILE.pdf to PS and back"; fi
			$PDFTOPS -level3 -origpagesizes -expand -nocrop -noshrink "$CDOCDIR/$FILE.pdf" "$OUTDIR/$tmpfile-clense.ps"
	                ps2pdf "$OUTDIR/$tmpfile-clense.ps" "$CDOCDIR/$FILE.pdf"
        	        rm -f "$OUTDIR/$tmpfile-clense.ps"
			#if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) Getting the number of pages in: $CDOCDIR/$FILE.pdf"; fi
			PGNUM=`pdftk "$CDOCDIR/$FILE.pdf" dump_data | grep NumberOfPages: | awk '{print$2}'`
		#fi
		
		#Create the input file for bookmarkign
		#if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) Creating bookmark file for: $CDOCDIR/$FILE.pdf"; fi
		echo "[/Title ($FILE) /Page $PGCOUNT /OUT pdfmark" >> $OUTDIR/$tmpfile-bookmark.info
		PGCOUNT=`expr $PGCOUNT + $PGNUM`
		
	
		# Split pages into  files:
		#if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) Splitting: $CDOCDIR/$FILE.pdf"; fi
		for (( PAGE=1; PAGE<=$PGNUM; PAGE++ ))
		do	
			#First make the stamp
			#Get width and height for the template
			pdftk $CDOCDIR/$FILE.pdf cat $PAGE output $OUTDIR/$tmpfile-$PAGE.pdf
			
			#Check page roration and swap height and with if detected
			ROT=`$PDFINFO $OUTDIR/$tmpfile-$PAGE.pdf | grep Page\ rot | awk '{print$3}'`
			if [ "$ROT" -eq 90 ]; then
				if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) Rotation Detected: "$ROT""; fi
                                HEIGHT=`$PDFINFO $OUTDIR/$tmpfile-$PAGE.pdf | grep Page\ size | awk '{print$3}'`
                                WIDTH=`$PDFINFO $OUTDIR/$tmpfile-$PAGE.pdf | grep Page\ size | awk '{print$5}'`
			else
				WIDTH=`$PDFINFO $OUTDIR/$tmpfile-$PAGE.pdf | grep Page\ size | awk '{print$3}'`
				HEIGHT=`$PDFINFO $OUTDIR/$tmpfile-$PAGE.pdf | grep Page\ size | awk '{print$5}'`
			fi
			if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) Width: $WIDTH Height: $HEIGHT"; fi
		
			#Now stamp
			"$APSDIR"/scripts/"$CSCRIPTDIR"/stamppdf.pl "$WIDTH" "$HEIGHT" "$ITEMNO" "$FILE" "Page: $PAGE of $PGNUM"
			#Now create the temp file for this page
			pdftk $OUTDIR/$tmpfile-$PAGE.pdf stamp $APSDIR/template.pdf output $OUTDIR/$tmpfile-marked-$PAGE.pdf
		done
	
		# Recombine the two pages again
		#if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) Recombining: $CDOCDIR/$FILE.pdf"; fi
		pdftk `ls -v $OUTDIR/$tmpfile-marked*.pdf` cat output $OUTDIR/$DOCNUM-$FILE.pdf
		DOCNUM=`expr $DOCNUM + 1`
		# Clean up
		rm -f $OUTDIR/$tmpfile-*.pdf $OUTDIR/$tmpfile-marked-*.pdf	
		if [ "$VERBOSE" == "TRUE" ]; then echo "$(date)"; fi
	done
	#Now combine all the PDF's into the final
	pdftk `ls -v $OUTDIR/*.pdf` cat output $OUTDIR/$PARCELNO-final.pdf
	
	#Bookmark the PDF
	gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=$OUTDIR/$PARCELNO-marked-final.pdf $OUTDIR/$PARCELNO-final.pdf $OUTDIR/$tmpfile-bookmark.info
	mv $OUTDIR/$PARCELNO-marked-final.pdf $DONEDIR/$PARCELNO-final.pdf
	
	#Set the Initial View of the PDF to show the Bookmark Outline
	"$APSDIR"/scripts/"$CSCRIPTDIR"/bmark.pl $DONEDIR/$PARCELNO-final.pdf $PARCELNO

	#Clean the out directory and reset the IFS
	rm -rf $OUTDIR
	IFS=$OLDIFS

	#Check if it was chosen to create the Burnable CD folder and do so
	if [ -n "$MKCD" ]; then
	        #Build the CD Directory
	        CDDIR="$INDIR/CD"
	        if [ ! -d "$CDDIR" ]; then
	                mkdir -p "$CDDIR"
	                chown apache:apache "$CDDIR"
	        fi
	        #Copy all PDF's to a Documents folder in the CDDIR
	        if [ ! -d "$CDDIR/Documents" ]; then
	                mkdir -p "$CDDIR/Documents"
	                chown apache:apache "$CDDIR/Documents"
	        fi
	        cp $INDIR/*.[pP][dD][fF] $CDDIR/Documents

	        #Copy the final PDF to the completed directory in the CDDIR
	        cp $DONEDIR/$PARCELNO-final.pdf $CDDIR
	fi
fi

if [ -n "$WRITE" ]; then
	#5/17/14 Change the default behavior to copy first keeping the original runsheet in the 
	#main document directory untouched

	#Write the hyperlinks to the runsheet
	cp $RUNSHEET $DONEDIR
	"$APSDIR"/scripts/"$CSCRIPTDIR"/writelink.pl "$DONEDIR"/`basename $RUNSHEET`
	
	if [ -n "$MKCD" ]; then
		#If MKCD Was chosen, hyperlink the CD RunSheet
        	cp $RUNSHEET $CDDIR
		"$APSDIR"/scripts/"$CSCRIPTDIR"/writelinkCD.pl "$CDDIR"/`basename $RUNSHEET`
	fi

fi

if [ -n "$UPLOAD" ]; then
	OLDIFS=$IFS
	IFS=$'\n'
	#This part of the script will upload the files to the brightonresources.net server 
	# and pass those parameters to the writelink.pl script to update the 
	#links in the runsheet
	#FTPUSER="brendanoilgas"
	#FTPPASS="Pershing3257@"
	FTPBASEDIR="/var/www/html/Shared"
	
	#Upload the files to brightonresources.com folling the assigned directory sturcture
	#Upload the "download.php" file to force downloads of pdf's
	REMOTEDIR=""$FTPBASEDIR"/"$PARCELNO""
	if [ ! -d "$REMOTEDIR" ]; then
       		 mkdir -p "$REMOTEDIR"
	fi
	
	if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) Copying: "$DOCDIR"/"$FTPFILE" "$REMOTEDIR""; fi
	cp "$APSDIR"/scripts/"$CSCRIPTDIR"/download.php "$REMOTEDIR"
	for FTPFILE in `ls "$DOCDIR"`
	do
		cp "$DOCDIR"/"$FTPFILE" "$REMOTEDIR"
	done
fi

if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) Moving "$INDIR" to "$PROCDIR""; fi
mv $INDIR $PROCDIR
echo "$(date) ####$PARCELNO: Complete"

dropboxCheck "$PROCDIR/$PARCEL/Completed/$PARCELNO-final.pdf"
#if [ "$VERBOSE" == "TRUE" ]; then echo "$(date) Sleeping for 5 until we can fix motherfucking dropbox"
#sleep 7
echo "$(date) dropBox sync complete"
