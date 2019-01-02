#!/bin/bash

#/*-------------------------------------------------------------------
#Author: Aaron Anthony Valoroso
#Date: December 17th, 2018
#License: GNU GENERAL PUBLIC LICENSE
#Email: valoroso99@gmail.com
#--------------------------------------------------------------------*/
path_location=""
current_location=$(pwd)

read -p "Enter Full Path Location: " path_location

# Remove the beginning and end slash of an incoming directory if it has it.
# - Have to do this because the find name option will spit out a warning
# - if I do not remove the slash.
if [ ! -z "$path_location" ] || [ "$path_location" != "" ]; then
    if [ ! "${path_location:0:1}" = '/' ]; then
        path_location="/$path_location"
    fi

    if [ "${path_location: -1}" = '/' ]; then
        path_location="${path_location::-1}"
    fi
else
    echo "There was an issue with the path location given..."
    exit
fi

pull_location="$path_location/scripts/pull.sh"
push_location="$path_location/scripts/push.sh"
test_location="$path_location/test/test.sh"

cd $path_location
if [ -f $pull_location ]; then
    cp $current_location/pull.sh $path_location/scripts
    chmod 775 $pull_location
    if [ -d "test" ]; then
        cp $current_location/pull.sh $path_location/test
        chmod 775 $path_location/test/pull.sh
    fi  
else
    echo "There was no pull script in that location."
fi

if [ -f $push_location ]; then
    cp $current_location/push.sh $path_location/scripts
    chmod 775 $push_location
    if [ -d "test" ]; then
        cp $current_location/push.sh $path_location/test
        chmod 775 $path_location/test/push.sh
    fi  
else
    echo "There was no push script in that location."
fi

if [ -f $test_location ]; then
    cp $current_location/test.sh $path_location/test/
    chmod 775 $test_location
else
    if [ -d $path_location/test ]; then
        echo "There was no test script in that location."
    fi
fi

exit