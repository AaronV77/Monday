#/bin/sh

#/*-------------------------------------------------------------------
#Author: Aaron Anthony Valoroso
#Date: November 14th, 2018
#License: GNU GENERAL PUBLIC LICENSE
#Email: valoroso99@gmail.com
#--------------------------------------------------------------------*/
argument=""
current_directory=$(pwd)
ip_address=None
username=""

# This will be a place to put all the files to transfer from the server.
if ! [ -d ~/Transfer ];
then
    mkdir ~/Transfer
fi

# Remove the beginning slash of an incoming directory if it has it.
# - Have to do this because the find name option will spit out a warning
# - if I do not remove the slash.
if [ ${1:0:1} == '/' ];
then
    argument="${1:1}"
else 
    argument=$1
fi

# The following section of code is spitting all the output to a null
# - device so that it won't be displayed. I am also creating a file
# - to send to the server that has the name of the directory or file
# - that I want to see if it exists on the server. I have to do it this
# - way because when I ssh over to the server I loose all my arguments
# - and can't see if the file that I need is actually there.
{
    touch $argument
    tar -czvf transfer.tar.gz $argument
    scp transfer.tar.gz $username@$ip_address:~/Transfer
    rm transfer.tar.gz $argument
} &> /dev/null

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
#       - Save the output of ls to a variable.
#       - Remove the file that we unpacked.
#       - Find the location in the storage server for the file or directory.
#       - There should only be one location in the server with the file name to
#           - download, and if there is more than one or none then print an error.
ssh $username@$ip_address -T > ~/Transfer/transfer.txt << 'EOSSH'

    cd ~/Transfer
    
    {
        tar -xzvf transfer.tar.gz
        rm transfer.tar.gz
    } &> /dev/null

    looking_for=$(ls)
    rm *

    array=(`find ~/Documents/storage -name "$looking_for"`) 
    len=${#array[*]}

    if [ $len == 0 ];
    then
        echo "There were no files found with that given name..."
    elif [ $len -ge 2 ];
    then
        echo "There were more than one file found with that name..."
    else
        echo ${array[0]}
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
to_download=$(tail -1 transfer.txt)
path_to_download=${to_download%/*}
rm transfer.txt

# Need to do SFTP because there is no way to transfer files from the server
# - back to the client. In order for the server to be able to scp files back
# - to the client, port 22 has to be open. The question is, how is this done
# - when my laptop is using hotspot through Version, and how about work WIFI?
# - So, this is the easiest way to do it from the client side. Lastly, I had
# - to break path up so that when I did the get command, I didn't get the warning
# - that the name didn't need to have a slash in it..
sftp $username@$ip_address -T << EOSSH
    cd $path_to_download
    get -r $argument
EOSSH

# Try and find the file that is getting added to the client computer to see if 
# - it is already in the file system. Now I have the starting point in /home, 
# - because you will get permission warnings if you dig through the root directories.
# - You can change this but just keep in mind that this search will take a little bit
# - longer to search through.
array=(`find /home -name "$argument"`)
len=${#array[*]}

# There will only be one location that the file will be and thats in ~/Transfer
# - to be moved to the current directory.

# If the find command has found the file or directory (once) on the file system then it
# - has found the one that got sftp to the Transfer directory. If the find command
# - has found the file or directory (twice) on the file system then it has found it in
# - the Transfer directory and the location that the user is looking to swap out for the 
# - one on the server. I then do some clean up and get rid of the file, and move it to
# - the location that the user is looking to replace.
if [ $len == 1 ];
then
    mv $argument $current_directory
elif [ $len == 2 ];
then
    absolute_path=${array[1]%/*}
    if [ -d ${array[1]} ]; then
        rm -rf ${array[1]}
        mv $argument $absolute_path
    elif [ -f ${array[1]} ]; then
        rm ${array[1]}
        mv $argument $absolute_path
    fi
else
    echo "There were more than one file found with that name..."
    rm -rf *
fi

# Put the user back into their current directory that they were working from.
cd $current_directory

# Clean up our transfer directory from the client.
if [ -d ~/Transfer ];
then
    rm -rf ~/Transfer
fi

# Useful URL's:
#   - https://www.digitalocean.com/community/tutorials/how-to-use-sftp-to-securely-transfer-files-with-a-remote-server
#   - https://www.tutorialspoint.com/unix/unix-basic-operators.htm
#   - https://zaiste.net/a_few_ways_to_execute_commands_remotely_using_ssh/
