#!/bin/bash

#/*-------------------------------------------------------------------
#Author: Aaron Anthony Valoroso
#Date: December 17th, 2018
#License: GNU GENERAL PUBLIC LICENSE
#Email: valoroso99@gmail.com
#--------------------------------------------------------------------*/
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
top_directory=""
item_type=""

# Get the credentails from the file.
credentials "DEFAULT"
#--------------------------------------------------------------------
# Check the incoming parameters such as items to pull from the server or
# - the error switch. The error switch will help provide extra output from
# - the compression and decompression of the items. Everything besides the 
# - error switch is going to be checked for emptiness and NULL. The error
# - switch is the only parameter that should have '-' in front of it, every
# - thing else will be ignored. Then lastly, I check for the ending and
# - beginning forward slash. The beginning slash needs to be there (so added) 
# - and the last forward slash (removed) does not need to be there. It
# - will be added to the array.
while [ $# -gt 0 ]; do
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

# Make sure that there are arguments to process and pass along.
if [ ${#incoming_items[*]} == 0 ]; then
    echo "There were zero arguments passed to the script..."
    echo "Exiting..."
    exit
fi

for argument in "${incoming_items[@]}"
do
    echo "--------------------"
    echo "Pushing: $argument"
    echo "--------------------"
    echo "Step-1: Packaging items and Transfering to server."

    top_directory=$(pwd | sed 's|.*/||')
    cd $current_directory

    if [ -f "$current_directory/$argument" ]; then
        item_type="file"
    elif [ -d "$current_directory/$argument" ]; then
        item_type="dir"
    else
        item_type="random"
    fi

    # Concatenate the current working directory with the incoming argument to 
    # - get the full absolute path. Then check to make sure that the incoming
    # - argument is either a directory or file, else exit. After that, I get 
    # - the number of files / folders of the argument, and will compress the 
    # - incoming argument and transfer it to the server. If there was an error, 
    # - print all of the output.
    absolute_path="$current_directory/$argument"
    if [ -d $absolute_path ] || [ -f $absolute_path ]; then

        argument_size=$(find $current_directory -name $argument | wc -l)
        if ! $compression transfer.tar.gz $argument 2> error_output.txt ; then cleanup; fi
        if ! scp transfer.tar.gz $username@$ip_address:~/Transfer 2> error_output.txt 1> output.txt; then cleanup; fi
        if ! rm transfer.tar.gz 2> error_output.txt ; then cleanup; fi

        if [ -f error_output.txt ]; then rm error_output.txt; fi

        if [ -f output.txt ]; then
            sed -i 's/^/\t/' output.txt
            if [ $error_switch -eq 1 ]; then
                cat output.txt
            fi
            rm output.txt
        fi

        echo "Finished."
        echo "Step-2: Replacing items in server."
    else 
        echo "File / Directory could not be found on Client..." 1> error_output.txt
        cleanup
    fi

    # This is the main guts of this script. In the first section of this heredoc I create
    # - a cleanup function that has a different than the previous cleanup function. This function
    # - will help clean up any time a command fails or a trap has been called. Then the next section
    # - we will move to the Transfer directory and decompress the packaged item, and then remove the
    # - archive file. Next, I will get the contents of the directory which should only be the one 
    # - file or folder, which I will then look for in the storage directory. The next section I make
    # - sure that everything had made it over to the server and if not then cleanup. The next section
    # - there are only three possible outcomes; the first is that the argument to be replace has only
    # - been found zero times (which is an error), greater than two times (which is an error), and then
    # - lastly only two occurences were found. In this if statment I make sure which element in the array
    # - to remove and the absolute path to replace with. Lastly, then some clean up.
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
        if ! cd \$HOME/Transfer 2> \$HOME/Transfer/error_output.txt ; then cleanup2; fi
        if ! $decompression transfer.tar.gz -m 2> error_output.txt ; then cleanup2; fi
        if ! rm transfer.tar.gz 2> error_output.txt ; then cleanup2; fi
        
        if [ -f error_output.txt ]; then rm error_output.txt; fi
        argument=\$(ls)

        argument_size_2=\$(find \$HOME/Transfer -name "\$argument" | wc -l)
        
        if [ "\$argument_size_2" != "$argument_size" ]; then
            pwd 1>> error_output.txt
            find \$HOME/Transfer -name "\$argument" | wc -l 1>> error_output.txt
            echo "Argument-1: $argument_size" 1>> error_output.txt
            echo "Argument-2: \$argument_size_2" 1>> error_output.txt
            echo "Not everything made it over to the darkside." 1>> error_output.txt
            cleanup2
        fi

        if [ $item_type == "dir" ]; then
            array=(\$(find \$HOME/$storage_location -type d -name "\$argument"))
        elif [ $item_type == "file" ]; then
            array=(\$(find \$HOME/$storage_location -type f -name "\$argument"))
        else
            array=(\$(find \$HOME/$storage_location -name "\$argument"))
        fi

        len=\${#array[*]}
        if [ \$len == 0 ]; then
            echo "Adding File / Directory to collection-1..."
            if ! mv \$argument \$HOME/$storage_location 2> error_output.txt ; then cleanup2; fi
            if [ -f error_output.txt ]; then rm error_output.txt; fi
        elif [ \$len -ge 2 ]; then
            array=(\$(find \$HOME/$storage_location -type d -name "$top_directory"))
            len=\${#array[*]}
            if [ \$len == 0 ] || [ \$len -ge 2 ]; then
                echo "There is more than one File / Directory that have the same name..." 1> error_output.txt
                cleanup2
            elif [ \$len -eq 1 ]; then
                if ! cd \${array[0]} 2> \${array[0]}/error_output.txt ; then cleanup2; fi
                if [ -f error_output.txt ]; then rm error_output.txt; fi
                temp=\$(pwd)
                array=(\$(find \$temp -name "\$argument"))
                len=\${#array[*]}
                if [ \$len == 1 ]; then
                    echo "Replacing File / Directory to collection-1..."
                    if [ -f "\$argument" ]; then
                        if ! rm "\$argument" 2> error_output.txt ; then cleanup2; fi
                    elif [ -d "\$argument" ]; then
                        if ! rm -rf "\$argument" 2> error_output.txt ; then cleanup2; fi
                    fi
                    if ! mv \$HOME/Transfer/\$argument . 2> error_output.txt ; then cleanup2; fi
                    if [ -f error_output.txt ]; then rm error_output.txt; fi
                else
                    echo "There is more than one File / Directory that have the same name..." 1> error_output.txt
                    cleanup2
                fi
            fi
        elif [ \$len -eq 1 ]; then
            echo "Replacing File / Directory to collection-2..."

            absolute_path=$(echo \${array[0]} | sed 's|\(.*\)/.*|\1|')
            if [ -d \${array[0]} ]; then
                if ! rm -rf \${array[0]} 2> error_output.txt ; then cleanup2; fi
            elif [ -f \${array[0]} ]; then
                if ! rm \${array[0]} 2> error_output.txt ; then cleanup2; fi
            fi
            if ! mv \$argument \$absolute_path 2> error_output.txt ; then cleanup2; fi
        fi

        rm -rf \$HOME/Transfer/*

        exit
EOSSH
    # Here we will check to see if the previous code ran into an error. If it did
    # - Then print an error message, remove the "Exiting..." from the end of the file
    # - and if the output.txt file is there then remove it. Lastly, we will call the 
    # - cleanup to exit the script, then print the "Finished." message and 
    # - remove the output.txt file if it exists.
    error=$(tail -1 output.txt)
    if [ "$error" == 'Exiting...' ]; then
        echo "Found errors in the heredoc..."
        head -n -1 output.txt 1> error_output.txt
        if [ -f output.txt ]; then
            rm output.txt
        fi
        cleanup
    else
        sed -i 's/^/\t/' output.txt
        cat output.txt
    fi

    echo "Finished."
    if [ -f output.txt ]; then
        rm output.txt
    fi
done

echo "--------------------"
exit

# Useful URL's:
#   - https://www.tutorialspoint.com/unix/unix-basic-operators.htm
#   - https://zaiste.net/a_few_ways_to_execute_commands_remotely_using_ssh/
