#!/bin/bash

#/*-------------------------------------------------------------------
#Author: Aaron Anthony Valoroso
#Date: December 17th, 2018
#License: GNU GENERAL PUBLIC LICENSE
#Email: valoroso99@gmail.com
#--------------------------------------------------------------------*/
ip_address=""
username=""
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

pull_location="$path_location/pull.sh"
push_location="$path_location/push.sh"
test_location="$path_location/test.sh"

cd $path_location
if [ -f $pull_location ]; then
    ip_address=$(grep $pull_location -e 'ip_address=')
    username=$(grep $pull_location -e 'username=')
    cp $current_location/pull.sh $path_location
    sed -i '/ip_address=/c\'$ip_address pull.sh
    sed -i '/username=/c\'$username pull.sh
    chmod 775 $pull_location
else
    echo "There was no pull script in that location."
fi

if [ -f $push_location ]; then
    ip_address=$(grep $push_location -e 'ip_address=')
    username=$(grep $push_location -e 'username=')
    cp $current_location/push.sh $path_location
    sed -i '/ip_address=/c\'$ip_address push.sh
    sed -i '/username=/c\'$username push.sh
    chmod 775 $push_location
else
    echo "There was no push script in that location."
fi

if [ -f $test_location ]; then
    ip_address=$(grep $test_location -e 'ip_address=')
    username=$(grep $test_location -e 'username=')
    cp $current_location/test.sh $path_location
    sed -i '/ip_address=/c\'$ip_address test.sh
    sed -i '/username=/c\'$username test.sh
    chmod 775 $test_location
else
    echo "There was no test script in that location."
fi

exit