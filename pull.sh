#!/bin/bash

#--------------------------------------------------------------------
#Author: Aaron Anthony Valoroso
#Date: December 17th, 2018
#License: GNU GENERAL PUBLIC LICENSE
#Email: valoroso99@gmail.com
#--------------------------------------------------------------------
# This function is used to clean up wherever the script is at. This function can be
# - ran when a command fails or when the user does a control c and etc.
cleanup () {
    if [ -f error_output.txt ]; then
        echo -e "\tHere is what caused the error: "
        sed -i 's/^/\t/' error_output.txt
        sed -i 's/^/\t/' error_output.txt
        cat error_output.txt
        rm error_output.txt
    fi
    echo -e "\tCleaning up...."
    if [ -d $HOME/Transfer ]; then
        rm -rf $HOME/Transfer
    fi
    echo "Exiting..."
    cd $current_directory || cd $HOME
    exit
}
trap cleanup 1 2 3 6
#--------------------------------------------------------------------
# This function is used to pull the information from the .locations file in order
# - setup the ssh calls. How this function works is by locating the file line number
# - of the head name of the ip_address and username. Then grab the next two lines and
# - pull the credentials that we will need. Once you grab the line, cut everything before
# - the equal sign and save.
credentials () {
    if [ -f $HOME/.monday/.locations ]; then
        line=$(grep -n "$1" $HOME/.monday/.locations | cut -d : -f 1)
        if [ ! -z "$line" ] || [ "$line" != "" ]; then
            line=$((line+1))
            username2=$(sed -n $line'p' $HOME/.monday/.locations | awk -F'=' '{print $2}')
            if [ -z "$username2" ] || [ "$username2" == "" ]; then
                echo "There was an issue with getting the username that you requested..."
                exit
            else
                username=$username2
            fi
        
            line=$((line+1))
            ip_address2=$(sed -n $line'p' $HOME/.monday/.locations | awk -F'=' '{print $2}')
            if [ -z "$ip_address2" ] || [ "$ip_address2" == "" ]; then
                echo "There was an issue with getting the password that you requested..."
                exit
            else
                ip_address=$ip_address2
            fi
        fi
    fi
}
#--------------------------------------------------------------------
incoming_items=()
error_switch=0
current_directory=$(pwd)
ip_address=""
username=""
storage_location="Documents/storage"
compression="tar -czf"
decompression="tar -xzf"

# Get the credentails from the file.
credentials "DEFAULT"
#--------------------------------------------------------------------
# The following section of code will check the following arguments that are 
# - passed to the following script. There are a total of four different arguments
# - that can be passed to this script. Please just type the alias name "push" or
# - "pull" then "-h" or "--h" to get more information about the possible arguments
# - that can be passed. For everything else that is passed in we will want to
# - check the validity, then I check for the ending and beginning forward slash. 
# - The beginning slash needs to be there (so added) and the last forward slash 
# - (removed) does not need to be there. It will be added to the array.
while [ $# -gt 0 ];
do
    if [ "$1" == "-error" ]; then
        error_switch=1
        compression="tar -czvf"
        decompression="tar -xzvf"
    elif [ "$1" == "-storage" ]; then
        shift
        storage_location="$1"
    elif [ "$1" == "-remote" ]; then
        shift
        incoming_argument=$(echo $1 | awk '{print toupper($0)}')
        credentials $incoming_argument
    elif [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
        cat $HOME/.monday/usage | more
        exit
    else
        argument=$1
        if [ ! -z "$argument" ] || [ "$argument" != "" ]; then
            if [ "${argument:0:1}" = '-' ]; then
                echo "There was a problem with the following argument: $argument"
                echo "Moving forward."
            else
                if [ "${argument:0:1}" = '/' ]; then
                    argument="${argument:1}"
                fi

                if [ "${argument: -1}" = '/' ]; then
                    argument=${argument::-1}
                fi

                incoming_items+=("$argument")
            fi
        else
            echo "There was a problem with the following argument: $argument"
            echo "Moving forward."
        fi
    fi
    shift
done

# This will be a place to put all the files to transfer from the server.
# - So we have to check to see if the directory already exits in the specific
# - location and if not then create the directory. Then change into that 
# - directory.
if ! [ -d $HOME/Transfer ]; then
    if ! mkdir $HOME/Transfer 2> error_output.txt ; then cleanup; fi 
fi
if ! cd $HOME/Transfer 2> error_output.txt ; then cleanup; fi 

# Make sure that there are arguments to process and pass along.
if [ ${#incoming_items[*]} == 0 ]; then
    echo "There were zero arguments passed to the script..."
    echo "Exiting..."
    exit
fi

for argument in "${incoming_items[@]}"
do
    echo "--------------------"
    echo "Pulling: $argument"
    echo "--------------------"
    echo "Step-1: Locating File on server."

    # This is the main part in the script and we are finding the file on ther server in order
    # - to pull to the client. In the first part of this section of code we are creating a 
    # - cleanup function that has a different name as the previoius clenaup function. I then
    # - setup the trap for any possiblity of a control sequenece from the user. In the next
    # - section of the code we move to the Transfer directory, and then try to find the number
    # - of occurences of the directory or file that the user is looking for. There is either
    # - zero occurences, to many occurences, or two occurences. The two occurences show up 
    # - once in the Transfer and in the storage directory. In the second if statment we move
    # - to the location above the item that the user is looking for, and package it up. Lastly,
    # - we print the number of files and directory for after the heredoc, and do some clean up.
    ssh $username@$ip_address -T 1> output.txt << EOSSH
        cleanup2 () {
            if [ -f error_output.txt ]; then
                cat error_output.txt
                rm error_output.txt
            fi
            if [ -d \$HOME/Transfer ]; then
                rm -rf \$HOME/Transfer/*
            fi
            echo "Exiting..."
            exit
        }
        trap cleanup 1 2 3 6
        if [ ! -d \$HOME/Transfer ]; then
            if ! mkdir \$HOME/Transfer 2> \$HOME/Transfer/error_output.txt ; then cleanup2; fi
        fi 
        if ! cd \$HOME/Transfer 2> \$HOME/Transfer/error_output.txt ; then cleanup2; fi 

        if [ ! -d \$HOME/$storage_location ]; then
            echo "There was a problem with your storage location..." > error_output.txt
            cleanup2
        fi

        array=(\$(find \$HOME/$storage_location -name "$argument"))
        len=\${#array[*]}
        if [ \$len == 0 ]; then
            echo "There were no files found with that given name..." 1> error_output.txt
            cleanup2
        elif [ \$len -eq 1 ]; then
            item=\${array[0]}
            item=$(echo \${item%/*})
            if ! cd \$item 2> error_output.txt ; then cleanup2; fi 
            if ! $compression \$HOME/Transfer/transfer.tar.gz $argument 2> error_output.txt ; then cleanup2; fi 
            lines=\$(find "\${array[0]}" | wc -l)
            echo \$lines
        elif [ \$len -ge 2 ]; then
            echo "There were more than one file found with that name..." 1> error_output.txt
            echo -e "\nHere are all the other items that we found with the same name." 1>> error_output.txt
            for i in "\${!array[@]}" 
            do 
            echo -e "\t\$i" "\${array[\$i]}" 1>> error_output.txt
            done
            echo "Try pulling the upper directory of the item." 1>> error_output.txt
            cleanup2

        fi

        if [ -f error_output.txt ]; then
            rm error_output.txt
        fi

        exit
EOSSH
    # Here we will check to see if the previous code ran into an error. If it did
    # - Then print an error message, remove the "Exiting..." from the end of the file
    # - and if the output.txt file is there then remove it. Lastly, we will call the 
    # - cleanup to exit the script.
    error=$(tail -1 output.txt)
    if [ "$error" == 'Exiting...' ]; then
        echo "Found errors in the heredoc..."
        head -n -1 output.txt 1> error_output.txt
        if [ -f output.txt ]; then
            rm output.txt
        fi
        cleanup
    fi

    # If there were no errors then the last line in the code should be the number of 
    # - lines that the system is transferring over to the client. Next, we remove the 
    # output file if it exists, and then print the following messages.
    argument_size=$(tail -1 output.txt)
    if [ -f output.txt ]; then
        rm output.txt
    fi
    echo "Finished."
    echo "Step-2: Pulling File"

    # Use scp to transfer the compressed files over to the client. Then save any output
    # - to a file. I have to use scp because there is no other way to pull / push files
    # - to the client from the remote system. This format of the following line is to 
    # - check the validity of the command and if it fails then we run the cleanup.
    if ! scp -r $username@$ip_address:"~/Transfer/transfer.tar.gz" . 2> error_output.txt 1> output.txt ; then cleanup; fi 

    # Decompress the file and then remove the archive file. These next two lines also 
    # - have the same format as the previous line, and if they fail then call the clean
    # - up function. We also store the output of the decompression command and if the 
    # - error switch is on, then print out the output.
    if ! $decompression transfer.tar.gz -m 2> error_output.txt 1> output.txt ; then cleanup; fi
    if ! rm transfer.tar.gz 2> error_output.txt ; then cleanup; fi 

    if [ $error_switch -eq 1 ]; then
        echo "Decompression output..."
        sed -i 's/^/\t/' output.txt
        cat output.txt
        if [ ! -f output.txt ]; then
            rm output.txt
        fi
    fi
    echo "Finished."

    # Get the number of lines of all the files and directories that was transfered over
    # - just to make sure that we got everything from the server. If the number from the
    # - server that we got does not match then there was an issue with the transfer. If 
    # - there is an issue and we are not running the test then pring an error message, 
    # - else print a 1. The one again signifies that there was an issue to the tests. Then
    # - we make sure to change back to the home directory and remove the Transfer directory.
    argument_size_2=$(find $argument | wc -l)
    if [ $argument_size != $argument_size_2 ]; then
        echo "Argument-1: $argument_size" 1> error_output.txt
        echo "Argument-2: $argument_size_2" 1>> error_output.txt
        echo "Not everything made it over from the dark side." 1>> error_output.txt
        cleanup
    fi

    # Try and find the file that is getting added to the client computer to see if 
    # - it is already in the file system. Now I have the starting point in /home, 
    # - because you will get permission warnings if you dig through the root directories.
    # - You can change this but just keep in mind that this search will take a little bit
    # - longer to search through.
    array=($(find $HOME -name "$argument"))
    len=${#array[*]}

    # If the find command has found the file or directory (once) on the file system then it
    # - has found the one that got scp to the Transfer directory. If the find command
    # - has found the file or directory (twice) on the file system then it has found it in
    # - the Transfer directory and the location that the user is looking to swap out for the 
    # - one on the server. If the find command has found anymore than three, then there is to
    # - many locations. In the second if statment I have to figure out what each item is in the
    # - array in order to know which one to replace and which one to remove.
    if [ $len == 1 ]; then
        echo "Step-3: Adding File / Directory to local collection..." 
        echo "Finished."
        if ! mv $argument $current_directory 2> error_output.txt ; then cleanup; fi
    elif [ $len == 2 ]; then
        echo "Step-3: Replacing File / Directory to collection..."
        echo "Finished."

        search="$current_directory/$argument"
        if [ $search == ${array[0]} ]; then
            destroy=$search
        elif [ $search == ${array[1]} ]; then
            destroy=$search
        fi
        
        absolute_path=$(echo $destroy | sed 's|\(.*\)/.*|\1|')
        if [ -d $destroy ]; then
            if ! rm -rf $destroy 2> error_output.txt ; then cleanup; fi
            if ! mv $argument $absolute_path 2> error_output.txt ; then cleanup; fi
        elif [ -f $destroy ]; then
            if ! rm $destroy 2> error_output.txt ; then cleanup; fi
            if ! mv $argument $absolute_path 2> error_output.txt ; then cleanup; fi
        fi
    else
        echo "ERROR: There were more than one file found with that name..." 1> error_output.txt
        cleanup
    fi
    if ! rm -rf $HOME/Transfer/* 2> error_output.txt ; then cleanup; fi

    # Clean up the folder on the server. This could not be done in the previous
    # - ssh because we need to scp over the tar'd file.
    ssh $username@$ip_address -T << EOSSH
        rm -rf \$HOME/Transfer/*
EOSSH
done
    # Put the user back into their current directory that they were working from.
    cd $current_directory || cd $HOME

echo "--------------------"

# Clean up our transfer directory on the client.
if [ -d $HOME/Transfer ]; then
    rm -rf $HOME/Transfer
fi

# Clean up any possible error files on the client.
if [ -f error_output.txt ]; then
    rm error_output.txt
fi
exit

# Useful URL's:
#   - https://www.digitalocean.com/community/tutorials/how-to-use-sftp-to-securely-transfer-files-with-a-remote-server
#   - https://www.tutorialspoint.com/unix/unix-basic-operators.htm
#   - https://zaiste.net/a_few_ways_to_execute_commands_remotely_using_ssh/
