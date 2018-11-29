#!/bin/sh

#/*-------------------------------------------------------------------
#Author: Aaron Anthony Valoroso
#Date: November 14th, 2018
#License: GNU GENERAL PUBLIC LICENSE
#Email: valoroso99@gmail.com
#--------------------------------------------------------------------*/
argument=""
argument_size=""
error_switch=0
test_switch=0
current_directory=$(pwd)
ip_address=None
username=""

storage_location="Documents/storage"
compression="tar -czf"
decompression="tar -xzf"
found_switch="not_found"

# Check the incoming parameters to see if either testing or printing errors
# - needs to be turned on.
i=0
for i in "$@"; do
    if [ $i == "-error" ]; then
        error_switch=1;
        compression="tar -czvf"
        decompression="tar -xzvf"
    elif [ $i == "-test" ]; then
        test_switch=1;
    fi
done

# This will be a place to put all the files to transfer from the server.
if ! [ -d ~/Transfer ]; then
    mkdir ~/Transfer
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

if [ $test_switch -eq 0 ]; then
    echo "Step-1: Locating File on server."
fi
ssh $username@$ip_address -T > ~/Transfer/transfer.txt << EOSSH

    cd ~/Transfer

    array=(\$(find \$HOME/$storage_location -name "$argument"))
    len=\${#array[*]}

    if [ \$len == 0 ]; then
        if [ $test_switch -eq 0 ]; then
            echo "There were no files found with that given name..."
            echo ""
        fi
        echo "1"
    elif [ \$len -ge 2 ]; then
        if [ $test_switch -eq 0 ]; then
            echo "There were more than one file found with that name..."
            echo ""
        fi
        echo "1"
    else
        echo \${array[0]}
        lines=\$(find \${array[0]} | wc -l)
        echo \$lines
        echo ""
    fi

    exit
EOSSH

# Move to the transfer directory, get the last line in the output file from
# - the ssh, then remove the last section on the path, and then remove the
# - output file. I have to get the tail of the file because I couldn't figure
# - out how to stop the ssh banner showing up in the output file, and I am
# - removing the last part of the path so that I have the absoute path of where
# - the file or directory is to download when I do the sftp. 
cd ~/Transfer
error=$(tail -1 transfer.txt)
if [ "$error" == '1' ]; then
    if [ $test_switch -eq 0 ]; then
        echo "ERROR: There was an issue retrieving the file."
        echo "$path_to_download"
    fi
    tail -2 transfer.txt
    rm transfer.txt
    cd $current_directory
    if [ -d ~/Transfer ]; then
        rm -rf ~/Transfer
    fi
    exit
fi
path_to_download=$(tail -3 transfer.txt | head -1)
number_of_lines=$(tail -2 transfer.txt | head -1)
rm transfer.txt
if [ $test_switch -eq 0 ]; then 
    echo "Finished."
fi

# Need to do SFTP because there is no way to transfer files from the server
# - back to the client. In order for the server to be able to scp files back
# - to the client, port 22 has to be open. The question is, how is this done
# - when my laptop is using hotspot through Version, and how about work WIFI?
# - So, this is the easiest way to do it from the client side. Lastly, I had
# - to break path up so that when I did the get command, I didn't get the warning
# - that the name didn't need to have a slash in it..
if [ $test_switch -eq 0 ]; then
    echo "Step-2: Pulling File"
fi

scp -r $username@$ip_address:$path_to_download . > output.txt

if [ $error_switch == 1 ]; then
    sed -i 's/^/\t\t/' output.txt
    cat output.txt
fi

rm output.txt

if [ $test_switch -eq 0 ]; then 
    echo "Finished."
fi

number_of_lines_2=$(find $argument | wc -l)
if [ $number_of_lines != $number_of_lines_2 ]; then
    if [ $test_switch -eq 0 ]; then 
        echo "Not everything made it over from the dark side."
    else
        echo 1
    fi
    rm -rf *
    cd $current_directory
    echo 1
    if [ -d ~/Transfer ]; then
        rm -rf ~/Transfer
    fi
    exit
fi

# Try and find the file that is getting added to the client computer to see if 
# - it is already in the file system. Now I have the starting point in /home, 
# - because you will get permission warnings if you dig through the root directories.
# - You can change this but just keep in mind that this search will take a little bit
# - longer to search through.
array=(`find /home -name "$argument"`)
len=${#array[*]}

# If the find command has found the file or directory (once) on the file system then it
# - has found the one that got scp to the Transfer directory. If the find command
# - has found the file or directory (twice) on the file system then it has found it in
# - the Transfer directory and the location that the user is looking to swap out for the 
# - one on the server. I then do some clean up and get rid of the file, and move it to
# - the location that the user is looking to replace.
if [ $len == 1 ]; then
    if [ $test_switch -eq 0 ]; then 
        echo "Step-3: Adding File / Directory to local collection..." 
        echo "Finished."
    fi
    mv $argument $current_directory
elif [ $len == 2 ]; then
    if [ $test_switch -eq 0 ]; then 
         echo "Step-3: Replacing File / Directory to collection..."
         echo "Finished."
    fi
    absolute_path=${array[1]%/*}
    if [ -d ${array[1]} ]; then
        rm -rf ${array[1]}
        mv $argument $absolute_path
    elif [ -f ${array[1]} ]; then
        rm ${array[1]}
        mv $argument $absolute_path
    fi
else
    if [ $test_switch -eq 0 ]; then 
        echo "ERROR: There were more than one file found with that name..."
    else
        echo 1
    fi
fi
rm -rf *

# Put the user back into their current directory that they were working from.
cd $current_directory

# Clean up our transfer directory from the client.
if [ -d ~/Transfer ]; then
    rm -rf ~/Transfer
fi

if [ $test_switch -eq 1 ]; then 
    echo 0
fi
# Useful URL's:
#   - https://www.digitalocean.com/community/tutorials/how-to-use-sftp-to-securely-transfer-files-with-a-remote-server
#   - https://www.tutorialspoint.com/unix/unix-basic-operators.htm
#   - https://zaiste.net/a_few_ways_to_execute_commands_remotely_using_ssh/
