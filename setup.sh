#!/bin/bash

#/*-------------------------------------------------------------------
#Author: Aaron Anthony Valoroso
#Date: January 2nd, 2019
#License: GNU GENERAL PUBLIC LICENSE
#Email: valoroso99@gmail.com
#--------------------------------------------------------------------*/
# This function will cleanup anything that the script has executed and format
# - the output of any possible errors. I have a variable inside the major script
# - that will be stored into an array to loop through and make sure to clenaup
# - at any point within the script. It is my attempt at trying to be able to 
# - cleanup at any given point.
cleanup () {
    if [ -f error_output.txt ]; then
        echo -e "\tHere is what caused the error: "
        if [ "$(uname -s)" == "Darwin" ]; then
            sed -i '' 's/^/        /' error_output.txt
        elif [ "$(uname -s)" == "Linux" ]; then
            sed -i 's/^/\t/' error_output.txt
            sed -i 's/^/\t/' error_output.txt
        fi
        cat error_output.txt
        rm error_output.txt
    fi
    for option in ${progression[@]}
    do
        if [ $progression -eq 1 ]; then
            rm -rf $HOME/.ssh
        elif [ $progression -eq 2 ]; then
            rm -rf $HOME/.ssh/sockets
        elif [ $progression -eq 3 ]; then
            rm $HOME/.ssh/monday_server_id_rsa
            rm $HOM/.ssh/monday_server_id_rsa.pub
        elif [ $progression -eq 4 ]; then
            cd $HOME/.ssh
            cp backup_config config
            rm backup_config
        elif [ $progression -eq 5]; then
            echo "There were changes done on the server that you will need to fix."
            echo "Do the following: "
            echo -e "\t Remove the client key from inside the .ssh/authorized_keys."
            echo -e "\t - It should be the last line in the file."
            echo -e "\t Reverse the no to yes in the PasswordAuthentication in /etc/ssh/sshd_config"
        fi
    done
    cd $current_directory
    exit
}
trap cleanup 1 2 3 6
#--------------------------------------------------------------------
# This function is used to remove the aliases within the .bashrc or .bash_profile. The 
# - file in which is avaliable is passed to the function, then we loop through the
# - array. The order is specific because the test aliases have the same part as the non-
# - test aliases. I search for the name of the alias in the file, get the line, then delete
# - the line if the line number is not empty or NULL.
alias_clear () {
    the_array=( "test_push" "test_pull" "push" "pull" )
    for b_alias in "${the_array[@]}"
    do
        if ! the_command=$($b_alias &> /dev/null); then
            line=$(grep -n "$b_alias ()" $1 | cut -d : -f 1)
            if [ ! -z "$line" ] || [ "$line" != "" ]; then
                sed -i -e $line'd' $1
            fi
        fi
    done 
}
#--------------------------------------------------------------------
bash_version=$(echo $BASH_VERSION)
bash_version=${bash_version:0:3}
if (( $(echo "$bash_version < 4.2" | bc -l) )); then
    echo "Your Bash version needs to be newer than 4.2..."
    echo "If you are using Linux then its a breeze, else if you are using Mac good luck..."
    exit
fi

ip_address=None
username=""
current_directory=$(pwd)
client_switch=0
server_switch=0
test_switch=0
progression=()

chmod 775 $current_directory/*
#--------------------------------------------------------------------
while test $# -gt 0; do
    if [ "$1" == "-client" ]; then
        client_switch=1
    elif [ "$1" == "-server" ]; then
        client_switch=1
    elif [ "$1" == "-develop" ]; then
        test_switch=1
    elif [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
        cat $current_directory/usage | more
        exit
    else
        echo "Unrecognized parameter: $1"
    fi
    shift
done

if [ $client_switch -eq 0 ] && [ $server_switch -eq 0 ]; then
    client_switch=1
    server_switch=1
fi

if [ $server_switch -eq 1 ]; then
    # Setup the ssh keys 
    if [ ! -d $HOME/.ssh ]; then
        if ! mkdir $HOME/.ssh 2> error_output.txt ; then cleanup; fi
        if ! mkdir $HOME/.ssh/sockets 2> error_output.txt ; then cleanup; fi
        progression+=(1)
    elif [ ! -d $HOME/.ssh/sockets ]; then
        if ! mkdir $HOME/.ssh/sockets 2> error_output.txt ; then cleanup; fi
        progression+=(2)
    fi

    if ! cd $HOME/.ssh 2> error_output.txt ; then cleanup; fi

    if ! ssh-keygen -t rsa 2> error_output.txt ; then cleanup; fi
    if ! mv id_rsa monday_server_id_rsa 2> error_output.txt ; then cleanup; fi
    if ! mv id_rsa.pub monday_server_id_rsa.pub 2> error_output.txt ; then cleanup; fi
    
    progression+=(3)

    occurences=$(grep -o 'Host '$ip_address $HOME/.ssh/config | wc -l)
    if [ $occurences -eq 0 ]; then
        echo -e "\nHost $ip_address\n    IdentityFile ~/.ssh/monday_server_id_rsa.pub" >> config
    else
        echo -e "ERROR: There was a Host in your config file already that was using this IP: $ip_address."
    fi
    
    occurences=$(grep -o 'Host *' $HOME/.ssh/config | wc -l)
    if [ $occurences -eq 0 ]; then
        echo -e "\nHost *\n    ControlMaster auto\n    ControlPath  ~/.ssh/sockets/%r@%h-%p\n    ControlPersist 20" >> config
    else
        echo -e "ERROR: There was a Host in your config file already that was just *."
    fi
    
    progression+=(4)

    key=$(cat monday_server_id_rsa.pub)

    # Setup the server
    ssh $username@$ip_address -T << EOSSH
        if [ ! -d \$HOME/.ssh ]; then
            mkdir \$HOME/.ssh
        fi

        if [ ! -d \$HOME/Transfer ]; then
            mkdir \$HOME/Transfer
        fi

        sudo apt install ssh

        cd \$HOME/.ssh
        echo $key >> authorized_keys
        chmod 644 authorized_keys

        echo "Please change the PasswordAuthentication to no from yes in the following file."
        echo "***Warning***"
        echo "Once you make this change then you will not be able to ssh into your server with password."
        echo "If you make a mistake, then please have another way of getting into your sever."
        echo "Then restart your ssh service with the following: sudo service ssh restart."
        exit
EOSSH

    progression+=(5)

    if ! cd $current_directory 2> error_output.txt ; then cleanup; fi
fi

if [ $client_switch -eq 1 ]; then

    script_directory=$(pwd)
    if ! cd $HOME 2> error_output.txt ; then cleanup; fi

    if [ -f .bashrc ]; then
        alias_clear .bashrc
    elif [ -f .bash_profile ]; then
        alias_clear .bash_profile
    fi

    if [ ! -d $HOME/.monday ]; then
        if ! mkdir .monday 2> error_output.txt ; then cleanup; fi
    fi
   
    if [ ! -d $HOME/.monday/scripts ]; then
        if ! mkdir .monday/scripts 2> error_output.txt ; then cleanup; fi
    fi

    if [ ! -f $HOME/.monday/.locations ]; then
        if ! cp $script_directory/.locations .monday/ 2> error_output.txt ; then cleanup; fi
    fi

    if ! cp $script_directory/.usage .monday/ 2> error_output.txt ; then cleanup; fi
    if ! cp $script_directory/push.sh .monday/scripts/ 2> error_output.txt ; then cleanup; fi
    if ! cp $script_directory/pull.sh .monday/scripts/ 2> error_output.txt ; then cleanup; fi

    if [ $test_switch -eq 1 ]; then
        if [ ! -d .monday/test ]; then
            if ! mkdir .monday/test 2> error_output.txt ; then cleanup; fi
        fi
        if ! cp $script_directory/push.sh .monday/test/ 2> error_output.txt ; then cleanup; fi
        if ! cp $script_directory/pull.sh .monday/test/ 2> error_output.txt ; then cleanup; fi
        if ! cp $script_directory/test.sh .monday/test/ 2> error_output.txt ; then cleanup; fi
    fi

    if [ -f .bashrc ]; then
        echo "push () { bash $HOME/.monday/scripts/push.sh \$@ ; }" >> .bashrc
        echo "pull () { bash $HOME/.monday/scripts/pull.sh \$@ ; }" >> .bashrc

        if [ $test_switch -eq 1 ]; then
            echo "test_push () { bash $HOME/.monday/test/push.sh \$@ ; }" >> .bashrc
            echo "test_pull () { bash $HOME/.monday/test/pull.sh \$@ ; }" >> .bashrc
        fi

        source .bashrc
    elif [ -f .bash_profile ]; then
        echo "push () { bash $HOME/.monday/scripts/push.sh \$@ ; }" >> .bash_profile
        echo "pull () { bash $HOME/.monday/scripts/pull.sh \$@ ; }" >> .bash_profile

        if [ $test_switch -eq 1 ]; then
            echo "test_push () { bash $HOME/.monday/test/push.sh \$@ ; }" >> .bash_profile
            echo "test_pull () { bash $HOME/.monday/test/pull.sh \$@ ; }" >> .bash_profile
        fi
        source .bash_profile
    else
        echo "Please make sure that you are using the bash shell..."
    fi
fi

if [ -f error_output.txt ]; then
    rm error_output.txt
fi

if [ -f $script_directory/error_output.txt ]; then
    rm $script_directory/error_output.txt
fi

chmod 644 $current_directory/*
exit
# Useful URL's:
#   - https://stackoverflow.com/questions/37876778/escape-dollar-sign-in-string-by-shell-script
#   - https://askubuntu.com/questions/521937/write-function-in-one-line-into-bashrc
#   - https://stackoverflow.com/questions/3327013/how-to-determine-the-current-shell-im-working-on
#   - https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server
#   - https://stackoverflow.com/questions/20410252/how-to-reuse-an-ssh-connection
#   - https://discussions.apple.com/thread/7826165
#   - https://eddmann.com/posts/transferring-files-using-ssh-and-scp/
