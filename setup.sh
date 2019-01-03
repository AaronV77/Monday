#!/bin/bash

#/*-------------------------------------------------------------------
#Author: Aaron Anthony Valoroso
#Date: November 14th, 2018
#License: GNU GENERAL PUBLIC LICENSE
#Email: valoroso99@gmail.com
#--------------------------------------------------------------------*/
cleanup () {
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
    elif [ "$1" == "-test" ]; then
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
    push_switch=1
    pull_switch=1
fi

if [ $server_switch -eq 1 ]; then
    # Setup the ssh keys 
    if [ ! -d $HOME/.ssh ]; then
        if ! mkdir $HOME/.ssh; then cleanup; fi
        if ! mkdir $HOME/.ssh/sockets; then cleanup; fi
        progression+=(1)
    elif [ ! -d $HOME/.ssh/sockets ]; then
        if ! mkdir $HOME/.ssh/sockets; then cleanup; fi
        progression+=(2)
    fi

    if ! cd $HOME/.ssh; then cleanup; fi
    if ! mkdir temp; then cleanup; fi
    if ! cd temp; then cleanup; fi

    if ! ssh-keygen -t rsa; then cleanup; fi
    if ! mv id_rsa monday_server_id_rsa; then cleanup; fi
    if ! mv id_rsa.pub monday_server_id_rsa.pub; then cleanup; fi
    if ! mv monday_server_id_rsa ../; then cleanup; fi
    if ! mv monday_server_id_rsa.pub ../; then cleanup; fi

    if ! cd ..; then cleanup; fi
    if ! rm -rf temp; then cleanup; fi
    
    progression+=(3)

    if ! cp config backup_config; then cleanup; fi

    echo "Host *\n    ControlMaster auto\n    ControlPath ~/.ssh/ssh_mux_%h_%p_%r" >> config
    echo "Host $ip_address\nIdentityFile ~/.ssh/monday_server_id_rsa.pub" >> config

    progression+=(4)

    key=$(cat monday_server_id_rsa.pub)

    # Setup the server
    ssh $username@$ip_address -T > output.txt << EOSSH
        if ! [ -d $HOME/.ssh ]; then
            mkdir $HOME/.ssh
        fi

        cd $HOME/.ssh
        echo $key >> authorized_keys
        chmod 644 authorized_keys

        echo "Please change the PasswordAuthentication to no from yes in the following file."
        echo "***Warning***"
        echo "Once you make this change then you will not be able to ssh into your server with password."
        echo "If you make a mistake, then please have another way of getting into your sever."
        read -p "Press enter to continue"
        nano /etc/ssh/sshd_config

        exit
EOSSH

    progression+=(5)

    if [ -f output.txt ]; then
        if ! rm output.txt; then cleanup; fi
    fi

    if ! cd $current_directory; then cleanup; fi
fi

if [ $client_switch -eq 1 ]; then

    script_directory=$(pwd)
    if ! cd $HOME; then cleanup; fi

    if [ -f .bashrc ]; then
        alias_clear .bashrc
    elif [ -f .bash_profile ]; then
        alias_clear .bash_profile
    fi

    if [ ! -d .monday ]; then
        if ! mkdir .monday; then cleanup; fi
    fi
   
    if [ ! -d .monday/scripts ]; then
        if ! mkdir .monday/scripts; then cleanup; fi
    fi

    if [ ! -f .monday/.locations ]; then
        if ! cp $script_directory/.locations .monday/; then cleanup; fi
    fi
    
    if ! cp $script_directory/usage .monday/; then cleanup; fi
    if ! cp $script_directory/push.sh .monday/scripts/; then cleanup; fi
    if ! cp $script_directory/pull.sh .monday/scripts/; then cleanup; fi

    if [ $test_switch -eq 1 ]; then
        if [ ! -d .monday/test ]; then
            if ! mkdir .monday/test; then cleanup; fi
        fi
        if ! cp $script_directory/push.sh .monday/test/; then cleanup; fi
        if ! cp $script_directory/pull.sh .monday/test/; then cleanup; fi
        if ! cp $script_directory/test.sh .monday/test/; then cleanup; fi
    fi

    if [ -f .bashrc ]; then
        echo "" >> .bashrc
        echo "push () { bash $HOME/.monday/scripts/push.sh \$@ ; }" >> .bashrc
        echo "pull () { bash $HOME/.monday/scripts/pull.sh \$@ ; }" >> .bashrc

        if [ $test_switch -eq 1 ]; then
            echo "test_push () { bash $HOME/.monday/test/push.sh \$@ ; }" >> .bashrc
            echo "test_pull () { bash $HOME/.monday/test/pull.sh \$@ ; }" >> .bashrc
        fi

        source .bashrc
    elif [ -f .bash_profile ]; then
        echo "" >> .bash_profile
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
