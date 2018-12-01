#!/bin/bash

home_dir=$HOME
current_dir=$(pwd)
array=($(find $HOME -name Monday))
len=${#array[*]}

if [ ! $len -eq 0 ]; then
    for i in "${array[@]}"
    do
        echo "Cleaning here: $i"
        cd $i
        # Remove the IP address.
        sed -i '/ip_address=/c\ip_address=None' pull.sh
	sed -i '/ip_address=/c\ip_address=None' push.sh
	sed -i '/ip_address=/c\ip_address=None' test.sh
	sed -i '/ip_address=/c\ip_address=None' setup.sh

        # Remove the username.
        sed -i '/username=/c\username=""' push.sh
        sed -i '/username=/c\username=""' pull.sh
        sed -i '/username=/c\username=""' test.sh
        sed -i '/username=/c\username=""' setup.sh
    done
fi

chmod 644 *
exit
