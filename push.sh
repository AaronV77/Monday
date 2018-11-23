#!/bin/sh

#/*-------------------------------------------------------------------
#Author: Aaron Anthony Valoroso
#Date: November 14th, 2018
#License: GNU GENERAL PUBLIC LICENSE
#Email: valoroso99@gmail.com
#--------------------------------------------------------------------*/
argument=""
error_switch=0
current_directory=$(pwd)
found_switch="not_found"
ip_address=None
username=""

# Allow all output / errors to be turned off and on.
if [ -n $2 ];
then
    if [ "$2" == "-error=on" ];
    then
        error_switch=1;
    fi
fi

# Remove the beginning and end slash of an incoming directory if it has it.
# - Have to do this because the find name option will spit out a warning
# - if I do not remove the slash.
argument=$1
if [ ${argument:0:1} == '/' ];
then
    argument="${argument:1}"
fi

if [ ${argument: -1} == '/' ];
then
    argument=${argument::-1}
fi

# Concatenate the current working directory with the incoming argument 
# - to get the full absolute path. 
echo "Step-1: Packaging items and Transfering to server."
absolute_path="$current_directory/$argument"
if [ -d $absolute_path ] || [ -f $absolute_path ];
then
    {
        tar -czvf transfer.tar.gz $argument
        scp transfer.tar.gz $username@$ip_address:~/Transfer
        rm transfer.tar.gz
    } > output.txt

    if [ $error_switch == 1 ];
    then
        sed -i 's/^/\t\t/' output.txt
        cat output.txt
    fi
    rm output.txt
    echo "Finished."
else 
    echo "File / Directory could not be found on Client..."
    exit
fi

# If the ending argument looks like 'EOSSH'
    # You can save variables within ssh.
    # You can use the find and ls commands.
# If the ending argument looks like EOSSH:
    # Tou can't look into any directorys or use the find command.
    # You can pass arguments declared outside of this ssh.

# This is the main guts of this project and make sure that you understand
# - what I'm trying to say above, because it can get annoying and the cause 
# - of a lot of head aches. Fist I ssh into the server and I want to save 
# - all output which should only be the absolute path to the file or directory
# - that I want to download to the client. Another important detail is to
# - make sure that you have a directory "Transfer" in your home directory!
# - THIS IS IMPORTANT. List of the following lines
#       - Chagne to that directory.
#       - Unpack the file or directory that we are looking for (Hiding all output).
#       - Remove the compressed file (Hiding all output).
#       - Save the output of ls to a variable (Hiding all output).
#       - Find the location in the storage server for the file or directory.
#           - If there is more than one location of said file or directory then
#           - we should exit and print an error. If there is zero locations, then
#           - we should just add the item to the storage area. If there is only
#           - one location then we want to delete the item and replace it with the
#           - updated item.
echo "Step-2: Replacing items in server."
ssh $username@$ip_address -T > output.txt << 'EOSSH'

    cd ~/Transfer

    tar -xzvf transfer.tar.gz
    rm transfer.tar.gz
    argument=$(ls)

    array=(`find ~/Documents/storage -name "$argument"`)      
    len=${#array[*]}

    if [ $len -ge 2 ];
    then
        echo "There is more than one File / Directory that have the same name..."
        if [[ -d ${array[0]} ]]; then
            rm -rf ${array[0]}
        elif [[ -f ${array[0]} ]]; then
            rm ${array[0]}
        fi
        exit
    fi

    if [ $len = 0 ];
    then
        echo "Adding File / Directory to collection..."
        mv $argument ~/Documents/storage
    else
        echo "Replacing File / Directory to collection..."

        if [[ -d ${array[0]} ]]; then
            rm -rf ${array[0]}
        elif [[ -f ${array[0]} ]]; then
            rm ${array[0]}
        fi
        mv $argument ${array[0]}
    fi
    exit
EOSSH

# Here I want to make sure that the user knows if the file is going to get replaced
# - or will be added. In the first section we add a tab to all output so it is more
# - visible on the screen but here is the problem. There is a line in the output
# - that we don't want to have a tab or it will get lost in the output. So, I do the 
# - following:
#       - Add a tab to all output lines.
#       - Save the last night to a separate file.
#       - Print the rest of the output rather than the last line.
#       - Remove the tab from the separate file and print.
if [ $error_switch == 1 ];
then
    sed -i 's/^/\t\t/' output.txt
    tail -1 output.txt > last_line.txt
    head -n -1 output.txt
    sed 's/\t//g' last_line.txt
    rm last_line.txt
else 
    tail -1 output.txt
fi
rm output.txt
echo "Finished."

# Useful URL's:
#   - https://www.tutorialspoint.com/unix/unix-basic-operators.htm
#   - https://zaiste.net/a_few_ways_to_execute_commands_remotely_using_ssh/
