#!/bin/bash

#/*-------------------------------------------------------------------
#Author: Aaron Anthony Valoroso
#Date: December 17th, 2018
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
argument=$1
while test $# -gt 0; do
    if [ "$1" = "-error" ]; then
        error_switch=1;
        compression="tar -czvf"
        decompression="tar -xzvf"
    elif [ "$1" = "-test" ]; then
        test_switch=1;
    fi
    shift
done

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

# Concatenate the current working directory with the incoming argument to 
# - get the full absolute path. Then check to make sure that the incoming
# - argument is either a directory or file, else exit. After that, I get 
# - the number of files / folders of the argument, and will compress the 
# - incoming argument and transfer it to the server. If there was an error, 
# - print all of the output.
if [ $test_switch -eq 0 ]; then
    echo "Step-1: Packaging items and Transfering to server."
fi
absolute_path="$current_directory/$argument"
if [ -d $absolute_path ] || [ -f $absolute_path ]; then
    {
        argument_size=$(find $argument | wc -l)
        compression="$compression transfer.tar.gz $argument"
        eval $compression
        scp transfer.tar.gz $username@$ip_address:~/Transfer
        rm transfer.tar.gz
    } > output.txt

    if [ $error_switch = 1 ]; then
        sed -i 's/^/\t\t/' output.txt
        cat output.txt
    fi
    rm output.txt
    if [ $test_switch -eq 0 ]; then
        echo "Finished."
    fi
else 
    if [ $test_switch -eq 0 ]; then
        echo "File / Directory could not be found on Client..."
    else
        echo "1"
    fi
    exit
fi

# This is the main guts of this script. In the first line I am sshing into 
# - my server, disabling the banner of ssh, and saving all output to a file to
# - be printed to terminal later. After that, I am using a heredoc to allow me
# - to write all the commands in this fashion. If I didn't use a heredoc, I would
# - not be able to use if statments. Next, I switch to our Transfer folder on the
# - server to decompress the file that we sent over, remove the packaged file, and 
# - then take the only file, and save the name to a variable. Next, I want to make 
# - sure that every file made it to the remote server, else print an error. Next, I 
# - want to make sure that the file / folder that we sent over is any where on the 
# - server. If there is no matching items then add, if there is one matching item then 
# - replace, and if there is more than one item then print error statment. How I
# - replace items in the server is just remove the item from where it lies, and then
# - move the new item in its exact same place. Lastly, some minor details to point
# - out is that all the variables created inside of the heredoc need to have a \ 
# - in front of them and all outside variables of the heredoc do not. The reason is
# - to break the parsing from local to remote in the ssh parsing of the heredoc.
if [ $test_switch -eq 0 ]; then
    echo "Step-2: Replacing items in server."
fi
ssh $username@$ip_address -T > output.txt << EOSSH

    cd ~/Transfer
    decompression="$decompression transfer.tar.gz -m"
    eval \$decompression
    rm transfer.tar.gz
    argument=\$(ls)

    if [ -d "\$argument" ]; then
        argument_size_2=\$(find "\$argument/" | wc -l)
    elif [ -f "\$argument" ]; then
        argument_size_2=\$(find "\$argument" | wc -l)
    fi
    
    if [ "\$argument_size_2" != "$argument_size" ]; then
        if [ $test_switch -eq 0 ]; then
            echo \$argument_size_2
            echo $argument_size
            echo "Not everything made it over to the darkside."
        else
            echo "1"
        fi
        rm -rf *
        exit
    fi

    array=(\$(find \$HOME/$storage_location -name "\$argument"))
    len=\${#array[*]}
    
    if [ \$len = 0 ]; then
        if [ $test_switch -eq 0 ]; then
            echo "Adding File / Directory to collection..."
        fi
        mv \$argument ~/Documents/storage
    elif [ \$len -ge 2 ]; then

        if [[ -d \${array[0]} ]]; then
            rm -rf \${array[0]}
        elif [[ -f \${array[0]} ]]; then
            rm \${array[0]}
        fi
        
        echo "There is more than one File / Directory that have the same name..."
        echo "1"

        exit
    else
        if [ $test_switch -eq 0 ]; then
            echo "Replacing File / Directory to collection..."
        fi

        if [[ -d \${array[0]} ]]; then
            rm -rf \${array[0]}
        elif [[ -f \${array[0]} ]]; then
            rm \${array[0]}
        fi
        mv \$argument \${array[0]}
    fi
    rm -rf *
    exit
EOSSH

# This section of code is to make sure that the user gets good feed back and understands
# - what is happening in the heredoc. If the error parameter eas passed to the system then
# - I want to print everything out from the previous section of code, else then I just want
# - to print the one line from the heredoc that was printed. In the first part of that if 
# - statment, I am adding a tab to every line in the output file and printing the contents.
if [ $error_switch = 1 ];
then
    sed -i 's/^/\t\t/' output.txt
    cat output.txt
else 
    output=$(tail -1 output.txt)
    if [ "$output" = "1" ]; then
        echo "1"
        exit
    fi

    if [ $test_switch -eq 0 ]; then
        echo -e "\t $output"
    fi

fi
rm output.txt
if [ $test_switch -eq 0 ]; then 
    echo "Finished."
else
    echo "0"
fi


# Useful URL's:
#   - https://www.tutorialspoint.com/unix/unix-basic-operators.htm
#   - https://zaiste.net/a_few_ways_to_execute_commands_remotely_using_ssh/
