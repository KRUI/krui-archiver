# !/bin/bash        
# Title           :krui-archiver.sh
# Description     :Rips the 89.7 webstream continuously, cuts the audio into hourly intervals,
#                 :and stores them into directories depending on the date of broadcast. 
# Author		  :Tony Andrys (aandrys@krui.fm)
# Date            :02-16-2014
# Version         :1.3    
# Usage		      :bash krui-archiver.sh
# Notes           :Ensure User Parameters are defined correctly for your system, see README.
# Dependencies    :streamripper (written by Greg Sharp - gregsharp@users.sourceforge.net)
#                 :postfix (for sending errors via email, comment this out if you're not using it)
#                 :BSD coreutils, or at the very least, use the BSD date if you want timestamps to work 
# Bash Version    :3.2.51(1)-release 
#=======================================================================================================

# User Parameters
prefix="Main"                                                         # Prefix used when naming files. Useful when archiving different stations into one directory.
radiostream="http://krui.student-services.uiowa.edu:8000/listen.m3u"  # Link to recording target (must be a webstream, obviously)
dest_path="/Users/tony/archives"                                      # Absolute path for recordings. No trailing slash!	
audio_sizecap=450000                                                  # Size cap of audio storage path in megabytes. As the size of the storage directory approaches
                                                                      # 90% of the cap defined here, emails will be sent.
notification_email="it@kruil.fm"                                      # Email that should processing errors and warnings

while [ 1 -le 2 ]
do
	
	##
	# Don't touch anything below this line unless you absolutely know what you are doing!!
	##

	# Time algorithm used to calculate the length of the recording.
	currentSeconds=$(date "+%S") #unadjusted with leading zero.
	currentMinutes=$(date "+%M") 
	
	# Yes, this is required because the BSD date won't give you a lowercame am/pm. 
	stamp=$(date "+%p" | tr '[:upper:]' '[:lower:]') 	

	# Filename formatting for finished recordings
	filename="$prefix--$(date "+%I-%M-%S").$stamp"

	if [ $currentSeconds -eq 0 ] 
	then
	    currentSeconds=0 #Set the date to zero to avoid issues with cutting "00" by zero
	elif [ $currentSeconds -lt 10 ] 
	then
		currentSeconds=$(date "+%S" | cut -f 2 -d '0') #Cut the leading zero off of the field if it exists
	fi
	adjSecondsTotal=$(($(($currentMinutes*60)) + $currentSeconds))
	adjSecondsRemaining=$((3600 - $adjSecondsTotal))
	riptime=$adjSecondsRemaining

	# Log the starting date/time of this capture 
	echo "# Archiver starting: ($(date "+%m-%d-%y") at $(date "+%I:%M:%S%p"))" >> error.log
	
	echo "---------------------------------"
	echo "-         KRUI Archiver         -"
	echo "---------------------------------"
	
	# Check that functioning copy of streamripper is available for use
	echo -n "> Checking for streamripper..."
	streamripper -v > /dev/null 2>> error.log
	if [ $? == 0 ] 
	then
		echo "OK!"
	else 
		printf "\n** FATAL ERROR: streamripper cannot be found! Streamripper must in the same directory as this script or in your '$PATH'."
		echo "I received an error -> Streamripper cannot be found! Streamripper must be in the same directory as this script or in your '$PATH'." | mail -s "CRITICAL: CANNOT FIND STREAMRIPPER" $notification_email -F "Archiving Robot"
		exit 1
	fi
	
	# Ensure we have internet access.
	echo -n "> Checking for an internet connection..."
	ping -c 1 www.google.com > /dev/null 2>> error.log
	if [ "$?" == 0 ] 
	then
		echo "OK!"
	else
		printf "\nWARNING: Unable to verify internet access. You may have issues connecting to streams outside of your LAN.\n"
	fi

	# Check if we can access to the storage path...
	echo -n "> Checking if the storage path is writable..."
	if [ -w $dest_path  ]
	then
		echo "OK!"
	else
		echo "** FATAL ERROR: $dest_path is not accessible! Ensure the directory exists and is writable by this application, then restart." | tee -a error.log
		echo "I received an error -> $dest_path is not accessible! Ensure the directory exists and is writable by this application, then restart. I AM NOT ARCHIVING CONTENT!!" | mail -s "CRITICAL: PERMISSIONS ERROR" $notification_email -F "Archiving Robot"
		exit 1	
	fi

	# Get size of audio directory...
	current_size=$(du -sm $dest_path | cut -f 1)

	# Check to see if we need to warn about audio storage path size...
	# Currently configured to warn when we approach 90% of cap
	warn_size=$(($audio_sizecap-$(($audio_sizecap/10))))

	# Ensure a folder to store the ripped file exists before moving on...
	echo -n "> Checking for folder in $dest_path for today's date..."
	fullpath=$dest_path/$(date "+%m-%d-%y")/
	result=$(ls $dest_path|grep $(date "+%m-%d-%y"))

	if test -z $result
	then
		printf "\n* $fullpath does not exist! Creating...\n"
		mkdir $fullpath 2>> error.log
		if [ $? != 0 ]
		then
			printf "** FATAL ERROR: Could not create $fullpath. Check permissions and try again.\n"| tee -a error.log
			echo "I received an error -> Could not create $fullpath. Check permissions and try again. I AM NOT ARCHIVING CONTENT!!" | mail -s "CRITICAL: PERMISSIONS ERROR." it@krui.fm -F "Archiving Robot"	
	
			exit 1
		fi
	else
		echo "OK!"
	fi
	
	echo -n "> Checking size of storage directory..."
	if [ $current_size -ge $audio_sizecap  ]
	then
		printf "\n* FATAL ERROR: Audio size cap reached! The application cannot continue.\n" | tee -a error.log
		echo "There is no space left to store programming. I cannot write any more recordings to $fullpath. I AM NOT ARCHIVING CONTENT!!" | mail -s "CRITICAL: NO SPACE REMAINING." $notification_email -F "Archiving Robot"	
		exit 1

	elif [ $current_size -ge $warn_size ]
	then
		printf "\n* WARNING: Audio size is approaching your storage cap. Backup your files soon!\n"
		# Send an email warning
		echo "I am running out of space to store programming! Please clear space on the drive that I am using to store recordings. My current storage path is $fullpath" | mail -s "Storage Capacity Low! (Used: $current_size MB)" $notification_email -F "Archiving Robot"	
	else
		echo "OK!"
	fi	
	printf "\n###\n" 
	echo "# Audio will be recorded from $radiostream"
	echo "# Stream will be ripped to disk as $filename.mp3 for $riptime seconds." 
	echo "# Finished audio will be stored to $fullpath"
	echo "# Audio storage directory is currently $(echo $current_size)MB of the $(echo $audio_sizecap)MB cap."	
	printf "###\n\n"
	streamripper $radiostream -a $filename -s -l $riptime -d $fullpath -c
	echo "Recording has halted!"
	printf "> Appending stop time to ripped file... \n"
	cd $fullpath
	base=$(basename $filename .mp3)
	newfilename=$base-$(date "+%I-%M-%S").$stamp.mp3
	mv $base.mp3 $newfilename 2>> ../error.log
	if [ "$?" == 0 ] 
	then
		echo "OK! ($newfilename)"
	else 
		echo "* WARNING: Could not rename file." 
	fi
	printf "> Cleaning up cuesheets...\n"
	rm *.cue > /dev/null 2>> ../error.log
	cd ..
	echo "OK!"
	echo "# Archiver shutting down: ($(date "+%m-%d-%y") at $(date "+%I:%M:%S%p"))" >> error.log
done 
