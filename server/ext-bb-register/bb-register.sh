#!/bin/bash

###  recieves pushed bb-hosts from the client
###  creates a file of the bb-hosts entry in a .d tree that should be included
###  in bb-hosts


trap 'exittrap $? $LINENO' EXIT ERR INT

exittrap() {
	exit=$1
	lineno=$2
	echo "we stopped.  why! code was $exit line $lineno"
	#we dont actually fucking die otherwise
  kill -TERM $$
	exit $exit
}

############ TODO:

#REQUIRES!!
#BBGHOSTS="0"
#lib/loadhosts.c:         * ghosthandling = 0 : Default BB method (case-sensitive, no logging, keep ghosts)

# listen for drops and clean up the host if we do a drop...


##add test logic here!!

## listen on the client channel, stay running unless our script changes

#this is the "test" that the client side of this pushes up the channel
servicename=hostpush
#use dir where bbhosts lives
dyndir="$(dirname $BBHOSTS)/bb-hosts.$servicename"
#make sure it exists and is writable
if ! [ -w $dyndir ]
 then
	echo "ERROR: $dyndir not writable" >&2
	exit 1
fi

echo "starting up on $(date)"

#store for later testing
mycmd=$0
mymd5sum=$(md5sum $mycmd)

genindex() {
	$dyndir/dynamichosts-index.sh
}

channel=status

#sometimes we run out of lines. so loop and restart
while true 
 do

#	trap 'exittrap $? $LINENO' EXIT ERR INT

	#requires the patched capture program so we line buffer instead of a ~~4k buffer
	$(dirname $mycmd)/hobbitd_capture-patched --tests="^$servicename" | while read line
	 do
	
#		trap 'exittrap $? $LINENO' EXIT ERR INT

		#the data could be on multiple lines, but we only want this one.  anything after a newline will be ignored	
		#this is the second line from _capture
		# sample:
		#	## @@client#745560 1351118819.067889 10.99.132.3 test.com test1 test1 
		#	client test.com.test1 test1 test 2 test 43 test
		#	test 1
		#	test 3
		#	## @@status#2745 1351283829.853785 10.99.132.3  thtrexmaple.com hostpush 1351285629 green  green 1351283441 0  0  1351283782 
		#	status thtrexmaple.com.hostpush green Fri Oct 26 20:37:09 UTC 2012 threefour
	
		if echo "$line" | grep -q "^$channel " 
		then
			echo "$line"
			echo "end of line"
	
	
			#now parse our data
			#sed doesnt do nongreedy, so perl..
			#the host here has commas instead of dots so replace
			MACHINE=$(echo "$line" |perl -pe 's/^'$channel' ([a-zA-z0-9].*?)\.'$servicename' .*/\1/g'|sed 's/,/./g')
			#our data.  field three through the end
			# because we're using status, we have to skip to field 4, not field 3 - status HAS to have a color.
			outputtests=$(echo "$line" | awk -v nr=4 '{ for (x=nr; x<=NF; x++) { printf $x " "; }; print " " }')
	
			bbline="0.0.0.0	$MACHINE	# prefer	$outputtests"
			
			echo "got one."
			echo "$line"
			echo "creating"
			echo "$bbline"
	
	
	##all this testing may be worthless...might as well just write the effing file.
			outfile="$dyndir/$MACHINE"
			if ! [ -e "$outfile" ]
			 then
				echo "creating new host file - $outfile"
				echo "$bbline" > "$outfile"
				genindex
			else		
				tmpfile="/tmp/.$(basename $outfile)"
				#already exists so compare
				echo "$bbline" > "$tmpfile"
				diff -q "$outfile" "$tmpfile" > /dev/null
				exit=$?
				if [ $exit -gt 0 ]
				 then
					echo "$outfile differs from $tmpfile"
					mv -f "$tmpfile" "$outfile"
					genindex
				else
					echo "files the same, cleaning up"
					rm "$tmpfile"
				fi
	
			fi
	
	
	
	#test to see if it exists.
	#diff it
	#now stick it in a file...
	
	#and run the genindex
	
	
	
		else
	
				#for testing
				echo "extras"
				echo "$line"
	
	
	
		fi
	
		#less than ideal, as it requires a line hit before it exits.
		#this -could- cause data loss, since we won't get and process any lines while we're not running
		#otoh, using a reasonable push interval in the client that shouldn't really be a problem..
		newmd5sum=$(md5sum $mycmd)
		if [ "x$newmd5sum" != "x$mymd5sum" ]
		 then
		 
			##if we restart more than 5 times (at least, nonzero.  zero maybe ok)
			##then launchd stops trying and waits ten minutes before it tries again
			#note that we only restart if we get a new line...
		 
			echo "restarting due to file changed: old $mymd5sum new $newmd5sum" >&2
			kill -TERM $$
			exit	0
		fi
	done
	echo "we ran out of lines restarting - $(date)"
done
echo "at the end, we broke out"

