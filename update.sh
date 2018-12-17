#!/bin/bash

ip_address=""
username=""
path_location=""
current_location=$(pwd)

read -p "Enter Full Path Location: " path_location

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