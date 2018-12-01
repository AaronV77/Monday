#/bin/bash

#/*-------------------------------------------------------------------
#Author: Aaron Anthony Valoroso
#Date: November 14th, 2018
#License: GNU GENERAL PUBLIC LICENSE
#Email: valoroso99@gmail.com
#--------------------------------------------------------------------*/

ip_address=None
username=""
current_directory=$(pwd)

# Setup the ssh keys 
if ! [ -d ~/.ssh ];
then
    mkdir ~/.ssh
    mkdir ~/.ssh/sockets
fi

cd ~/.ssh
printf "Host *\n    ControlMaster auto\n    ControlPath ~/.ssh/ssh_mux_%h_%p_%r" > config

ssh-keygen -t rsa
mv id_rsa server_id_rsa
mv id_rsa.pub server_id_rsa.pub
mv server_id_rsa ~/.ssh
mv server_id_rsa.pub ~/.ssh

echo "Host $ip_address\nIdentityFile ~/.ssh/server_key.pub" >> config

cd ~/.ssh
key=$(cat server_id_rsa.pub)

# Setup the server
ssh $username@$ip_address -T > server_key << EOSSH
    if ! [ -d ~/.ssh ];
    then
        mkdir ~/.ssh
    fi

    cd ~/.ssh
    echo $key >> authorized_keys
    chmod 644 authorized_keys

    echo "Please change the PasswordAuthentication to no from yest in the following file."
    echo "***Warning***"
    echo "Once you make this change then you will not be able to ssh into your server with password."
    echo "If you make a mistake, then please have another way of getting into your sever."
    read -p "Press enter to continue"
    nano /etc/ssh/sshd_config

    if ! [ -d ~/Transfer ];
    then
        mkdir ~/Transfer
    fi

    exit
EOSSH

# Setup the aliases
scripts_directory=$(pwd)
cd ~/
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
elif [ $SHELL == "csh" ];
then
    echo "csh is not supported..."
elif [ $SHELL == "ksh" ];
then
    echo "ksh is not supported..."
elif [ $SHELL == "sh" ];
then
    echo "sh is not supported..."
elif [ $SHELL == "zsh" ];
then
    echo "zsh is not supported..."    
elif [ $SHELL == "tsh" ];
then
    echo "tsh is not supported..."
fi

# Useful URL's:
#   - https://stackoverflow.com/questions/37876778/escape-dollar-sign-in-string-by-shell-script
#   - https://askubuntu.com/questions/521937/write-function-in-one-line-into-bashrc
#   - https://stackoverflow.com/questions/3327013/how-to-determine-the-current-shell-im-working-on
#   - https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server
#   - https://stackoverflow.com/questions/20410252/how-to-reuse-an-ssh-connection
#   - https://discussions.apple.com/thread/7826165
#   - https://eddmann.com/posts/transferring-files-using-ssh-and-scp/
