#!/bin/bash
#This script adds, deletes, and edits entries in the batch.cfg file
#Postcondition: Exit0 - Normal Program Execution, E1 - No Batch File does not Exist

BAT_FILE="/root/batch.cfg"
TMP_FILE="/root/tbatch.cfg"


# dagdagan() checks the title for any special characters and finally appends the temporary batch file
# used by Add
# Expects: $1 - Username, $2 - File
dagdagan()
{
while true; do
	echo -n "Title: "
	read IN3
	# check input for the title for special characters
	echo $IN3 | grep -qE ['.@#%^&*()_+=\[\{:";<>?/']
	if [ $? -eq 0 ]; then
		# exit status 0 means special characters are found
		echo "Er: No Special Characters Allowed"
		# continue asking the user for the title
		continue
	elif [ -z "$IN3" ]; then
		# Check if entry is empty
		echo "Er: Empty String"
		continue
	else
		# input is valid 
		break
	fi
	done

# perform append on temp batch file
echo "$IN3.$1:$2" >> $TMP_FILE
}

# linisin() Makes sures that there are no duplicates in the batch file
# accessible to menu by typing C 
# Expects - No Arguments
linisin()
{
# unique sort (disregard titles by using the resulting row 2 if period after the title is the delimeter
sort -u -t. -k2 $TMP_FILE > temp.txt
mv temp.txt $TMP_FILE
}


# palitan() is used to replace the file/s intended to be copied to the user
# used by Edit
# Expects - $1 - Line Number to be replaced, $2 - Title, $3 - Username, $4 File
palitan()
{
IN="seed"

# Until loop will keep asking for a file until the file is accepted or the user pressed enter that will yield a zero length string
until [ -z "$IN" ]; do
echo "Editing User $3 of File $4"
echo -n "Enter new File (default: no change): "
read IN
if [ -z "$IN" ]; then
	# Do nothing when string is zero length
	continue

# Check if the new File is the same as the old one 
elif [[ "$IN" = $4 ]]; then
	echo "Er: NEW file required!"
	continue

# Check if the new File will create a duplicate if entered
elif $(grep -qE ^*.$3:$IN$ $TMP_FILE); then
	echo "Er: Input will create duplicate"
	continue

# Check whether the new File exists
elif [[ ! -e "/root/Config/$IN" ]]; then
	echo "Er: File Does not exist"

	# Notify the user that the file does not exist and gives option to add the entry anyway if file is to be created later
	echo -n "Add Anyway ? [y/n]: "
	read IN0
	if [[ ! "$IN0" = ['Yy'] ]]; then
	# Entering a character other than y will repeat the loop
	continue
	fi
fi
# If no error are found or the user forced to add anyway, replace the line using sed
# use the substitute command and -i option to push changes to the file
# syntax: substitute at line number/ all contents of that line / replace with this pattern
sed -i "$1"s"/.*/$2.$3:$IN/" $TMP_FILE
return
done
}


#Check the batch file
if [[ ! -e "$BAT_FILE" ]]; then
	echo "Er: batch.cfg does not exist"

	# Ask user to create the batch file if nonexistent
	echo -n "Create one now ? [y/n] : "
	read IN
	
	if [[ "$IN" = ['Yy'] ]]; then
	touch $BAT_FILE
	
	else
	# if user did not type y, script will exit at exit code 1 (batch file does not exist)
	exit 1
	fi

else
	echo "Batch File is Healthy"
	
fi

#Create scratch for the bat file
cp $BAT_FILE $TMP_FILE
clear

while true
do

echo "[Batch.cfg Editor]"
#compare the temp batch file and batch file, if the two are different the prompt will display the Save prompt
cmp --silent $BAT_FILE $TMP_FILE && echo -n "[A]dd, [E]dit, [D]elete, [Q]uit ? : " || echo -n "[A]dd, [E]dit, [D]elete, [S]ave, [Q]uit ? : "
read IN
WARN=""

case "$IN" in
[Aa])
	echo "[+]--Add Mode"

	while true; do
		echo -n "Username: "
		read IN1
		# Check username has special characters
		echo $IN1 |  grep -qE ['.@#%^&*()_+=\[\{:;<>?']
	#'
	if [ $? -eq 0 ]; then
		# repeat input if special characters exists
		echo "Er: No Special Characters Allowed"
		continue

	elif [ -z "$IN1" ]; then
		# Check if entry is empty
		echo "Er: Empty String"
		continue
	else
		break
	fi
	done

	while true; do
		echo -n "File: "
		read IN2

		if [ -z "$IN2" ]; then
			# Check if entry is empty
			echo "Er: Empty String"
			continue
		else
			break
		fi

	done
	
	# Check whether the inputted username and file is still not present at the batch file
	grep -qE ^*.$IN1:$IN2$ $TMP_FILE

	if [ $? -ne 0 ] ; then
		# Combination is unique
		
		#Check if usern exists
		grep -q ^$IN1: /etc/passwd
		[ $? -ne 0 ] && WARN=" User Does not Exist",$WARN
		
		# Check if user is a system account		
		USER_ID=$( grep ^$IN1: /etc/passwd | cut -d: -f3 )
		[[ -n "$USER_ID" ]] && [[ "$USER_ID" -lt 1000 ]] && WARN=" System Account",$WARN
		
		# Check if the file is existing			
		[[ ! -e "/root/Config/$IN2" ]] &&  WARN="File does not exist",$WARN

		
		if [[ -n "$WARN" ]]; then
			
			# Display warnings
			echo "Warnings: ${WARN::-1}"
			
			# Ask to forcefully add the entry			
			echo -n "Add Anyway ? [y/n]: "
			read IN0
		
			if [[ "$IN0" = ['Nn'] ]]; then
				echo "Add Canceled."
			elif [[ "$IN0" = ['Yy'] ]]; then
				dagdagan $IN1 $IN2
			else
				echo "Interpreting No, Add Canceled."
			fi
		else
			# No warnings call the dagdagan funtion
			dagdagan $IN1 $IN2
		fi
	else
		# Combination is a duplicate, exit Add
		echo "Er: No Duplicates Allowed, Exiting Add"
	fi
	;;
[Ee])
	echo "[/]--Edit Entries"

	while true; do

	echo -n "Username: "
	read IN1
	
	if [ -z "$IN1" ]; then
		# Check if entry is empty
		echo "Er: Empty String"
		continue
	else
		break
	fi
	done
	# Check if the username exists
	grep -qE .$IN1: $TMP_FILE
	if [[ $? -eq 0 ]]; then
	# usename exists
	# edit lines that contains the username
	# by using cat -n to print the tmp file with number lines, use translate so that grep can be used efficiently
	for TMP_LINE in $(cat -n -s $TMP_FILE | tr "\t" "-" | tr -s " " | cut -c 2- | grep -E ^*.$IN1:*); do	
	((CTR = CTR+1 ))
	
	#TMP_LINE looks like 5-mrs.maetabs:F4
	
	LS=${TMP_LINE%.*}
	#LS looks like 5-mrs

	B1=${TMP_LINE#*.}
	#B1 looks like maetabs:F4	

	#palitan 5 mrs maetabs F4
	palitan ${LS%-*} ${LS#*-} ${B1%%:*} ${B1#*:} 
done
	else
	# username did not exist
		echo "No Entry of Username Found."
	fi	
	;;
[Dd])
	echo "[x]--Delete Entry"

	while true; do
	echo -n "Username: "
	read IN1

	if [ -z "$IN1" ]; then
		# Check if entry is empty
		echo "Er: Empty String"
		continue
	else
		break
	fi
	done

	while true; do
	echo -n "File: "
	read IN2

	if [ -z "$IN2" ]; then
		# Check if entry is empty
		echo "Er: Empty String"
		continue
	else
		break
	fi
	done

	# invert the grep selection to yield only lines without the entered username file combination
	# then redirect to a temp file
	grep -vE ^*.$IN1:$IN2$ $TMP_FILE  > temp.txt
	
	# if the temp file is the same as the temp batch file
	if $(cmp --silent temp.txt $TMP_FILE); then
		# say no entries of that combination was found
		echo "No Entries to Delete."
	# then clean up the mess
	rm temp.txt
	else
		# if the temp is different, rename the temp file to the temp batch file
		mv temp.txt $TMP_FILE
	fi
	;;
[cC])
	linisin
	;;
[sS])
	#Save changes in the temp file to the batch file
	if $(cmp --silent $BAT_FILE $TMP_FILE);then
	 	echo "Er: No changes were detected"
	else
		cp $TMP_FILE $BAT_FILE
	 	echo "Changes Applied"
	fi
	;;
[qQ])
	# quit the script and clean up the mess
	rm $TMP_FILE
	break
	;;
*)
	# input was unexpected
	echo "Er: Unexpected Input"
	;;
esac
done
exit 0
