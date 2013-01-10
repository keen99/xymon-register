#!/bin/bash

#we HAVE to send a color - because we're using status.
COLOR=green

service=hostpush

##

# find our list of tests

testdir=/etc/xymon/clienttests.d

#all we do is grab the contents of all the files and build our line
#unsafe for unsafe file names but can't find a way around that.  so make sure our files aren't unsafe
tests=$(cat $testdir/*|tr '\n' ' ')

if [[ "$tests" == "" ]]
 then
 	#we didn't find any tests, we must not be green...
 	#could be maybe should be red instead
	COLOR=yellow
fi

tests="$tests
"  #add a blank line for xymon's diplay to be happy



echo "$(date) setting status for $service to $COLOR and tests to $tests"
$BB $BBDISP "status $MACHINE.$service $COLOR $tests"
