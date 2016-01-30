#! /bin/bash

#################################################################################
# Copyright (C) Steven M. Japalucci - All Rights Reserved
# Unauthorized copying of this file, via any medium is strictly prohibited
# Proprietary and confidential
# Written by Steven M Japalucci RHCE RHCT <steve.japalucci@gmail.com>, August 2013
#################################################################################

#Config file defining queues
source /usr/local/bin/aps/conf/config.sh 
QUEUES="$APSDIR/conf/queues"
WAITTIME=1

#Create PID file so that we only alow one instance of the processing to run
pidfile="/var/run/aps.pid"
if [ -e $pidfile ]; then
	pid=`cat $pidfile`
	if kill -0 >&1 > /dev/null $pid; then
		exit 1
	else
		rm $pidfile
	fi
fi
echo $$ > $pidfile

#Check if dropbox is running, if not, start it
#dropbox running 
#DSTATUS=$?
#if [ $DSTATUS -eq 0 ]; then
#	dropbox start
#fi
 

OLDIFS=$IFS
IFS=$'\n'
for LINE in `cat $QUEUES`
do
	#Get the queue path from the config file
	QUEUE=`echo "$LINE" | awk '{print$1}'`
	#Get the Customer script path from the config file that is associated with the queue for execution
	CSNAME=`echo "$LINE" | awk '{print$2}'`
	for JOB in `ls -l "$QUEUE" | grep "^d" | awk '{print$9}'`
	do
		if [ "$JOB" == 'Processed' ] || [ "$JOB" == 'Error' ] || [ "$JOB" == 'recycle_bin' ]; then 
			continue
		fi
		#Check for an index before we process, if no index skip
		if [ ! -f "$QUEUE/$JOB/index.xls" ]; then
		        echo "$(date) $QUEUE/$JOB/index.xls Run Sheet not found!" 2>&1 >> $LOGFILE
		else
			#Test if dropbox is still syncing or up to date with the directory
			#if test "`dropbox filestatus $QUEUE/$JOB | grep 'up to date'`"; then
			
			#if it's found, and it hasent been accesed in 5 minutes process it. We need to give all the files time to copy over
			if test "`find $QUEUE/$JOB/index.xls -amin +"$WAITTIME"`"; then
				/usr/local/bin/dropbox filestatus "$QUEUE/$JOB" | grep 'up to date' &>/dev/null
				STATUS=$?
				if [ $STATUS -eq 0 ]; then
				
					#Check if the queue is a special configuration for the mkpdf script
					#First grab the basename of the queue to check
					QBASE=`basename $QUEUE`
					#Define the custom configs in the if statement
					#Custom config for DMC queue, this queue builds a burnable CD directory fpor the DMC company
					#--FIXME--
					#Maybe add extra options to the config file instead of doing this string check for queues.
					#Leave the config out of the script
					if [ "$QBASE" == "DMC" ]; then 
						#Run the DMC script
						echo "$(date) Attempting to processs "$QUEUE"/"$JOB" with the DMC script" 2>&1 >> $SLOGFILE
						$APSDIR/mkpdf.sh -Cpvuwi $QUEUE/$JOB -n $CSNAME 2>&1 >> $LOGFILE
					else
						#Default script
						echo "$(date) Attempting to processs "$QUEUE"/"$JOB" with the default APS script" 2>&1 >> $SLOGFILE
						$APSDIR/mkpdf.sh -pvuwi $QUEUE/$JOB -n $CSNAME 2>&1 >> $LOGFILE
					fi
				else
					echo "$(date) Dropbox check: Waiting for "$QUEUE"/"$JOB" to finish syncing" 2>&1 >> $LOGFILE
				fi
			else
				echo "$(date) Find check: Waiting for "$QUEUE"/"$JOB" to finish syncing" 2>&1 >> $LOGFILE
			fi
		fi
	done
done

#Remove the PID file to alow other instances to run
rm $pidfile
IFS=$OLDIFS
