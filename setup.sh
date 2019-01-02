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
        elif [ $progression -eq 5]
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
ip_address=None
username=""
current_directory=$(pwd)
client_switch=0
server_switch=0
progression=()
#--------------------------------------------------------------------
while test $# -gt 0; do
    if [ "$1" == "-client" ]; then
        client_switch=1
    elif [ "$1" == "-server"]
        client_switch=1
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
        mkdir $HOME/.ssh
        mkdir $HOME/.ssh/sockets
        progression+=(1)
    elif [ ! -d $HOME/.ssh/sockets ]; then
        mkdir $HOME/.ssh/sockets
        progression+=(2)
    fi

    cd $HOME/.ssh
    mkdir temp
    cd temp

    ssh-keygen -t rsa
    mv id_rsa monday_server_id_rsa
    mv id_rsa.pub monday_server_id_rsa.pub
    mv monday_server_id_rsa ../
    mv monday_server_id_rsa.pub ../

    cd ..
    rm -rf temp
    
    progression+=(3)

    cp config backup_config

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
        rm output.txt
    fi

fi

if [ $client_switch -eq 1 ]; then
    # Setup the aliases
    scripts_directory=$(pwd)
    cd $HOME/
    SHELL=$(ps -p $$ -oargs=)
    if [ $SHELL == "bash" ];
    then
        echo "bash"
        if [ -f .bashrc ]
        then
            echo "" >> .bashrc
            echo "push () { bash "$current_directory"/push.sh \$@ ; }" >> .bashrc
            echo "pull () { bash "$current_directory"/home/valorosoa/pull.sh \$@ ; }" >> .bashrc
            source .bashrc
        else
            echo "" >> .bash_profile
            echo "push () { bash "$current_directory"/push.sh \$@ ; }" >> .bash_profile
            echo "pull () { bash "$current_directory"/pull.sh \$@ ; }" >> .bash_profile
            source .bash_profile
        fi
    else
        echo "Sorry the shell you are using is not supported..."
        exit
    fi
fi
# Useful URL's:
#   - https://stackoverflow.com/questions/37876778/escape-dollar-sign-in-string-by-shell-script
#   - https://askubuntu.com/questions/521937/write-function-in-one-line-into-bashrc
#   - https://stackoverflow.com/questions/3327013/how-to-determine-the-current-shell-im-working-on
#   - https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server
#   - https://stackoverflow.com/questions/20410252/how-to-reuse-an-ssh-connection
#   - https://discussions.apple.com/thread/7826165
#   - https://eddmann.com/posts/transferring-files-using-ssh-and-scp/
