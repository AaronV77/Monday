#!/bin/bash

#/*-------------------------------------------------------------------
#Author: Aaron Anthony Valoroso
#Date: December 17th, 2018
#License: GNU GENERAL PUBLIC LICENSE
#Email: valoroso99@gmail.com
#--------------------------------------------------------------------*/
incoming_items=()
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
while test $# -gt 0; do
    if [ "$1" = "-error" ]; then
        error_switch=1
        compression="tar -czvf"
        decompression="tar -xzvf"
    elif [ "$1" = "-test" ]; then
        test_switch=1;
    else
        incoming_items+=("$1")
    fi
    shift
done

# This will be a place to put all the files to transfer from the server.
# - So we have to check to see if the directory already exits in the specific
# - location and if not then create the directory.
if ! [ -d ~/Transfer ]; then
    mkdir ~/Transfer
fi
cd ~/Transfer

for argument in "${incoming_items[@]}"
do
    if [ $test_switch -eq 0 ]; then
        echo "--------------------"
        echo "Pulling: $argument"
        echo "--------------------"
    fi
    # Remove the beginning and end slash of an incoming directory if it has it.
    # - Have to do this because the find name option will spit out a warning
    # - if I do not remove the slash.
    if [ ! -z "$argument" ] || [ "$argument" != "" ]; then
        if [ "${argument:0:1}" = '/' ]; then
            argument="${argument:1}"
        fi

        if [ "${argument: -1}" = '/' ]; then
            argument=${argument::-1}
        fi
    else
        if [ $test_switch -eq 0 ]; then
            echo "There was an issue with the argument given..."
        else
            echo "1"
        fi
        exit
    fi

    # If we are testing then don't print this output.
    if [ $test_switch -eq 0 ]; then
        echo "Step-1: Locating File on server."
    fi

    # Log onto the server to look for the specified argument that the user
    # - has passed into the script. Move into the Transfer directory in the home
    # - if the directory does not exist then create the directory. If the file / 
    # - directory was found on the server then compress the item to the specified 
    # - locaiton, print the number of files and folders and then a space. If the 
    # - item was not found then print an error message and the number one. The one 
    # - indecates that there  was an error after the heredoc to quite and exit. Lastly, 
    # - remove the the transfer directory in home on the server.
    ssh $username@$ip_address -T > output.txt << EOSSH

        if [ ! -d ~/Transfer ]; then
            mkdir ~/Transfer
        fi 

        cd ~/Transfer

        array=(\$(find \$HOME/$storage_location -name "$argument"))
        len=\${#array[*]}
        if [ \$len == 0 ]; then
            if [ $test_switch -eq 0 ]; then
                echo "There were no files found with that given name..."
            fi
            echo "error"
        elif [ \$len -ge 2 ]; then
            if [ $test_switch -eq 0 ]; then
                echo "There were more than one file found with that name..."
            fi
            echo "error"
        else
            item=\${array[0]}
            item=$(echo \${item%/*})
            cd \$item
            $compression $HOME/Transfer/transfer.tar.gz $argument
            lines=\$(find \${array[0]} | wc -l)
            echo \$lines
        fi

        exit
EOSSH

    # Here we will check to see if the previous code ran into an error. If there was 
    # - an error, then check to make sure that we are not running a test. If we are
    # - running tests then don't print the previous error and if we are not then print
    # - a one to signify to the testing system that an error has occured. Lastly, 
    # - remove the output file, change back to the user directory, and then delete
    # - the transfer directory.
    error=$(tail -1 output.txt)
    if [ "$error" == 'error' ]; then
        error=$(tail -2 output.txt | head -1)
        if [ $test_switch -eq 0 ]; then
            echo "$error"
        else 
            echo 1
        fi

        if [ -f output.txt ]; then
            rm output.txt
        fi

        cd $current_directory

        if [ -d ~/Transfer ]; then
            rm -rf ~/Transfer
        fi
        exit
    fi

    # If there were no errors then the last line in the code should be the number of 
    # - lines that the system is transferring over to the client. Next, we remove the 
    # output file, and print a message if we are not running the tests. 
    argument_size=$(tail -1 output.txt)

    if [ -f output.txt ]; then
        rm output.txt
    fi

    if [ $test_switch -eq 0 ]; then 
        echo "Finished."
    fi

    # Print a messeage of the next section that we will start to run.
    if [ $test_switch -eq 0 ]; then
        echo "Step-2: Pulling File"
    fi

    # Use scp to transfer the compressed files over to the client. Then save any output
    # - to a file. I have to use scp because there is no other way to pull / push files
    # - to the client from the remote system.
    scp -r $username@$ip_address:"$HOME/Transfer/transfer.tar.gz" . > output.txt

    # Decompress the file and then remove the archive file. I save the output to a variable
    # - because I didn't find any other to add it to the above output file.
    comp_output=$($decompression transfer.tar.gz -m; rm ~/Transfer/transfer.tar.gz)

    # If the error argument was given then print out any possible errors that have happened
    # - previously, then remove the output file, and if we are not running tests then print
    # - the finishing statment.
    if [ $error_switch == 1 ]; then
        echo $comp_output >> output.txt
        sed -i 's/^/\t/' output.txt
        cat output.txt
    fi

    if [ -f output.txt ]; then
        rm output.txt
    fi

    if [ $test_switch -eq 0 ]; then 
        echo "Finished."
    fi

    # Get the number of lines of all the files and directories that was transfered over
    # - just to make sure that we got everything from the server. If the number from the
    # - server that we got does not match then there was an issue with the transfer. If 
    # - there is an issue and we are not running the test then pring an error message, 
    # - else print a 1. The one again signifies that there was an issue to the tests. Then
    # - we make sure to change back to the home directory and remove the Transfer directory.\
    argument_size_2=$(find $argument | wc -l)
    if [ $argument_size != $argument_size_2 ]; then
        if [ $test_switch -eq 0 ]; then 
            echo "Not everything made it over from the dark side."
        else
            echo "1"
        fi
        cd $current_directory
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
    array=($(find /home -name "$argument"))
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

        search="$current_directory/$argument"
        if [ $search == ${array[0]} ]; then
            destory=$search
        elif [ $search == ${array[1]} ]; then
            destory=$search
        fi
        
        absolute_path=$(echo $destory | sed 's|\(.*\)/.*|\1|')
        if [ -d $destroy ]; then
            rm -rf $destroy
            mv $argument $absolute_path
        elif [ -f destroy ]; then
            rm $destroy
            mv $argument $absolute_path
        fi
    else
        if [ $test_switch -eq 0 ]; then 
            echo "ERROR: There were more than one file found with that name..."
        else
            echo "1"
        fi
    fi
    rm -rf ~/Transfer/*

    # Clean up the folder on the server. This could not be done in the previous
    # - ssh because we need to scp over the tar'd file.
    ssh $username@$ip_address -T << EOSSH
        rm -rf ~/Transfer/*
EOSSH
done
    # Put the user back into their current directory that they were working from.
    cd $current_directory

if [ $test_switch -eq 0 ]; then
    echo "--------------------"
fi

# Clean up our transfer directory from the client.
if [ -d ~/Transfer ]; then
    rm -rf ~/Transfer
    
fi

# Signal to the tests that the system ran without any errors.
if [ $test_switch -eq 1 ]; then 
    echo "0"
fi
# Useful URL's:
#   - https://www.digitalocean.com/community/tutorials/how-to-use-sftp-to-securely-transfer-files-with-a-remote-server
#   - https://www.tutorialspoint.com/unix/unix-basic-operators.htm
#   - https://zaiste.net/a_few_ways_to_execute_commands_remotely_using_ssh/
