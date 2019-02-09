#!/bin/bash
# The bida_bida script makes use of the batch.cfg located in /root to distribute files to respective users. Check log_file.txt for errors.
# Postcondition: Exit0 - Normal Program Execution, E1 - Bad Batch File, E2 - Unknown error has occured

LOG_PATH="/root/log_file.txt"
BAT_FILE="/root/batch.cfg"

# idalamo() function moves the file to the home directory of the user
# Expects: $1 - Username  $2 - File in /root/Config to move
# Postcondition: Exit0 - Copy is Successful, E1 - User does not exit, E2 - Copying to system account other than root, E3 - User have no home directory, E4 - User has home directory but is missing, E5 - File does not exit,  E6 - File Already Exists,  

idalamo()
{
#Test if user exists by using grep command
grep -qE ^$1: /etc/passwd
#Check exit status, 0 indicates a match is found
if [ $? -eq 0 ]; then
	#User Exists, now check uid
	USER_ID=$( grep ^$1: /etc/passwd | cut -d: -f3 )
	[[ $USER_ID -lt 1000 ]] && [[ $USER_ID -ne 0 ]] && return 2
	#User Exists, now get the home directory
	USER_HOME=$( grep ^$1: /etc/passwd | cut -d: -f6 )
	#USER_HOME should be non empty if directory exists
	[[ -z "$USER_HOME" ]] && return 3
	#USER_HOME should be existing	
	[[ ! -e "$USER_HOME" ]] && return 4
	#The file to be copied should be existing in ~/Config
	[[ ! -e "/root/Config/$2" ]] && return 5
	#The file to be copied should not be copied already
	[[ -e "$USER_HOME/$2" ]] && return 6
	#Checks are complete, perform copy
	cp /root/Config/$2 $USER_HOME
	return 0
else
	#User Does not Exist
	return 1
fi
}


#Check The Logfile
if [[ ! -e $LOG_PATH ]]; then
	echo "Bad log file creating one now"
	touch $LOG_PATH 
	echo "$(date +"%D %r") : Log Start " > $LOG_PATH
fi


#Check the batch file
if [[ ! -e $BAT_FILE ]]; then
	echo "Er: batch.cfg does not exist, run master_data to create one"
	echo "$(date +"%D %r") : batch.cfg missing " >> $LOG_PATH
	#Terminate Program with exit code 1
	exit 1
else
	echo "$(date +"%D %r") : Batch file opened ---------- " >> $LOG_PATH
fi

for BAT_LINE in $( cat $BAT_FILE ); do
	#Remove Salutations
	B1=${BAT_LINE#*.}
	#echo "$CTR ${B1%:*} ${B1#*:}"
	
	#Use string manipulation to split the batch file line
	# let B1 = maetaba:F2
	# %%:* means remove the longest pattern that starts with a colon = maetaba
	# #*:  means remove the pattern that will end on a colon = F2
	idalamo ${B1%%:*} ${B1#*:}

	# The Logfile is populated by interpreting the exit status of idalamo()
	case "$?" in
	0)	
		echo "$(date +"%D %r") : File ${B1#*:} is copied to User ${B1%:*}" >> "$LOG_PATH" 
		;;
	1)
		echo "$(date +"%D %r") : User ${B1%:*} does not exist" >> "$LOG_PATH" 
		;;	
	2)	
		echo "$(date +"%D %r") : User ${B1%:*} is a system account" >> $LOG_PATH 
		;;
	3) 
 		echo "$(date +"%D %r") : User ${B1%:*} has no home directory" >> $LOG_PATH 
		;;
	4) 
		echo "$(date +"%D %r") : User ${B1%:*} home directory is missing" >> $LOG_PATH 
		;;
	5)
		echo "$(date +"%D %r") : File ${B1#*:} does not exist" >> $LOG_PATH 
		;;
	6) 
 		echo "$(date +"%D %r") : File ${B1#*:} already exists at ${B1%:*} home" >> $LOG_PATH 
		;;
	
	*)
		echo "$(date +"%D %r") : Unknown Error Occured" >> $LOG_PATH
		exit 2
		;;	
	esac
done

echo "$(date +"%D %r") : Script terminated without unexpected errors " >> "$LOG_PATH"

echo -n "Display Log File [y/n] ? : "
read IN
	if [[ $IN = ['Yy'] ]]; then
	cat $LOG_PATH
	else
	echo "Interpreting No, exiting."
	fi


exit 0
