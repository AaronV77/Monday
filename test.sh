#!/bin/bash

#/*-------------------------------------------------------------------
#Author: Aaron Anthony Valoroso
#Date: December 17th, 2018
#License: GNU GENERAL PUBLIC LICENSE
#Email: valoroso99@gmail.com
#--------------------------------------------------------------------*/
ip_address=None
username=""
storage_location="Documents/storage"
pull_switch=0
push_switch=0

# Setup all of the moveable files for testing.
mkdir Monday_Testing
cd Monday_Testing

# Check the incoming arguments for independent testing capabilities.
argument=$1
while test $# -gt 0; do
    if [ "$1" = "-push" ]; then
        push_switch=1
    elif [ "$1" = "-pull" ]; then
        pull_switch=1
    fi
    shift
done

if [ $push_switch -eq 0 ] && [ $pull_switch -eq 0 ]; then
    push_switch=1
    pull_switch=1
fi

if [ $push_switch -eq 1 ]; then
    mkdir monday_testing
    touch monday_testing/example_1.txt
    touch monday_testing/example_2.txt
    mkdir test-1
    mkdir test-2
    echo "------------------------------"
    echo "Testing - Push.sh"
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Testing adding a directory w/ files."
    results=$(push monday_testing -test)
    ssh -T $username@$ip_address > output.txt << EOF
        outcome=\$(find \$HOME -type d -name monday_testing | wc -l)
        if [ \$outcome -gt 1 ]; then
            echo "1"
        else 
            cd ~/$storage_location
            rm -rf monday_testing
            echo "0"
        fi
EOF

    outcome=$(cat output.txt)
    if [ "$results" == "0" ] || [ "$outcome" == "0" ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo "--------------------------------------------------"
        push monday_testing -error
        echo "----------------------------"
        curr_dir=$(pwd)
        echo "Current Path: $curr_dir"
        echo "----------------------------"
        curr_dir=$(ls)
        echo "Current Directory Contents: "
        echo "--------------------------------------------------"
    fi
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Testing replacing a directory w/ an added file."
    touch monday_testing/example_2222.txt
    results=$(push monday_testing -test=on)
    ssh -T $username@$ip_address > output.txt << EOF
        outcome=\$(find \$HOME -type f -name example_2222.txt | wc -l)
        if [ \$outcome -gt 1 ]; then
            echo "1"
        else 
            cd ~/$storage_location
            rm -rf monday_testing
            echo "0"
        fi
EOF

    outcome=$(cat output.txt)
    if [ "$results" == '0' ] || [ "$outcome" == '0' ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo "--------------------------------------------------"
        push monday_testing -error
        echo "----------------------------"
        curr_dir=$(pwd)
        echo "Current Path: $curr_dir"
        echo "----------------------------"
        curr_dir=$(ls)
        echo "Current Directory Contents: "
        echo "--------------------------------------------------"
    fi
    rm -rf monday_testing
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Testing adding a directory with more than one location."
    ssh -T $username@$ip_address > output.txt << EOF
        cd \$HOME/$storage_location
        mkdir second_testing
        mkdir second_testing/monday_testing
EOF

    results=$(push monday_testing -test)
    if [ "$results" == '1' ]; then 
        echo "PASSED"
    else
        echo "FAILED"
        echo "--------------------------------------------------"
        push monday_testing -error
        echo "----------------------------"
        curr_dir=$(pwd)
        echo "Current Path: $curr_dir"
        echo "----------------------------"
        curr_dir=$(ls)
        echo "Current Directory Contents: "
        echo "--------------------------------------------------"
    fi
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Testing adding a just a file."
    touch monday_test.txt
    results=$(push monday_test.txt -test)
    ssh -T $username@$ip_address > output.txt << EOF
        outcome=\$(find \$HOME -type f -name monday_test.txt | wc -l)
        if [ \$outcome -gt 1 ]; then
            echo "1"
        else 
            cd ~/$storage_location
            rm monday_test.txt
            echo "0"
        fi
EOF

    outcome=$(cat output.txt)
    if [ "$results" == '0' ] || [ "$outcome" == '0' ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo "--------------------------------------------------"
        push monday_test.txt -error
        echo "----------------------------"
        curr_dir=$(pwd)
        echo "Current Path: $curr_dir"
        echo "----------------------------"
        curr_dir=$(ls)
        echo "Current Directory Contents: "
        echo "--------------------------------------------------"
    fi
    rm monday_test.txt
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Testing adding two folders at once."
    results=$(push test-1 test2 -test)
    ssh -T $username@$ip_address > output.txt << EOF
        outcome=\$(find \$HOME -type d -name test-1 | wc -l)
        if [ \$outcome -gt 1 ]; then
            echo "1"
        else 
            cd ~/$storage_location
            rm -rf test-1
            outcome=\$(find \$HOME -type d -name test-1 | wc -l)
            if [ \$outcome -gt 1 ]; then
                echo "1"
            else
                rm -rf test-2
                echo "0"
            fi
        fi
EOF

    outcome=$(cat output.txt)
    if [ "$results" == '0' ] || [ "$outcome" == '0' ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo "--------------------------------------------------"
        push test-1 test2 -error
        echo "----------------------------"
        curr_dir=$(pwd)
        echo "Current Path: $curr_dir"
        echo "----------------------------"
        curr_dir=$(ls)
        echo "Current Directory Contents: "
        echo "--------------------------------------------------"
    fi
    echo "------------------"    
    #---------------------------------------------------------------------------------
    echo "Cleaning Up the Push tests."
    ssh -T $username@$ip_address > output.txt << EOF
        cd \$HOME/$storage_location
        rm -rf second_testing
EOF
    rm -rf ~/Monday_Testing/*
    #---------------------------------------------------------------------------------
    echo "------------------------------"
    if [ $pull_switch -eq 1 ]; then
        echo ""
    fi
fi


if [ $pull_switch -eq 1 ]; then
    ssh -T $username@$ip_address << EOF
        cd \$HOME/$storage_location
        mkdir monday_testing_1
        touch monday_testing_1/something_1.txt
        touch monday_testing_1/something_2.txt
        mkdir monday_testing_2
        touch the_test_file.txt
EOF

    echo "------------------------------"
    echo "Testing - Pull.sh"
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Pulling a directory with files."
    outcome=$(pull monday_testing_1 -test)
    directory=$(ls)
    if [ "$directory" == "monday_testing_1" ] && [ "$outcome" == '0' ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo "--------------------------------------------------"
        pull monday_testing_1 -error
        echo "----------------------------"
        curr_dir=$(pwd)
        echo "Current Path: $curr_dir"
        echo "----------------------------"
        curr_dir=$(ls)
        echo "Current Directory Contents: "
        echo "--------------------------------------------------"
    fi
    rm -rf monday_testing_1
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Pulling an empty directory."
    outcome=$(pull monday_testing_2 -test)
    directory=$(ls)
    if [ "$directory" == "monday_testing_2" ] && [ "$outcome" == 0 ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo "--------------------------------------------------"
        pull monday_testing_2 -error
        echo "----------------------------"
        curr_dir=$(pwd)
        echo "Current Path: $curr_dir"
        echo "----------------------------"
        curr_dir=$(ls)
        echo "Current Directory Contents: "
        echo "--------------------------------------------------"
    fi
    rm -rf monday_testing_2
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Pulling a file."
    outcome=$(pull the_test_file.txt -test)
    directory=$(ls)
    if [ "$directory" == "the_test_file.txt" ] && [ "$outcome" == 0 ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo "--------------------------------------------------"
        pull the_test_file.txt -error
        echo "----------------------------"
        curr_dir=$(pwd)
        echo "Current Path: $curr_dir"
        echo "----------------------------"
        curr_dir=$(ls)
        echo "Current Directory Contents: "
        echo "--------------------------------------------------"
    fi
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Pulling a file thats already on the system."
    first_stamp=$(stat --printf=%y the_test_file.txt | cut -d. -f1)
    sleep 5
    ssh -T $username@$ip_address << EOF
        echo "This is something extra" > \$HOME/$storage_location/the_test_file.txt
EOF

    outcome=$(pull the_test_file.txt -test)
    second_stamp=$(stat --printf=%y the_test_file.txt | cut -d. -f1)
    if [ "$first_stamp" == "$second_stamp" ]; then
        echo "FAILED"
        echo "--------------------------------------------------"
        pull the_test_file.txt -error
        echo "----------------------------"
        curr_dir=$(pwd)
        echo "Current Path: $curr_dir"
        echo "----------------------------"
        curr_dir=$(ls)
        echo "Current Directory Contents: "
        echo "--------------------------------------------------"
    else
        echo "PASSED"
    fi
    rm the_test_file.txt
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Pulling a file that is on the server twice."
    ssh -T $username@$ip_address > output.txt << EOF
        cd \$HOME/$storage_location
        touch monday_testing_2/the_test_file.txt
EOF

    outcome=$(pull the_test_file.txt -test)
    if [ "$outcome" == 1 ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo "--------------------------------------------------"
        push the_test_file.txt -error
        echo "----------------------------"
        curr_dir=$(pwd)
        echo "Current Path: $curr_dir"
        echo "----------------------------"
        curr_dir=$(ls)
        echo "Current Directory Contents: "
        echo "--------------------------------------------------"
    fi  
    rm output.txt
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Pulling two folders."
    outcome=$(pull monday_testing_1 monday_testing_2 -test)
    directory_contents=$(ls | wc -l)
    if [ "$directory_contents" == "2" ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo "--------------------------------------------------"
        pull monday_testing_1 monday_testing_2 -error
        echo "----------------------------"
        curr_dir=$(pwd)
        echo "Current Path: $curr_dir"
        echo "----------------------------"
        curr_dir=$(ls)
        echo "Current Directory Contents: "
        echo "--------------------------------------------------"
    fi
    rm -rf monday_testing_1
    rm -rf monday_testing_2
    echo "------------------"    
    #---------------------------------------------------------------------------------
    echo "Cleaning Up the Pull tests."
    ssh -T $username@$ip_address > output.txt << EOF
        cd \$HOME/$storage_location
        rm -rf monday_testing_1
        rm -rf monday_testing_2
        rm the_test_file.txt
EOF
    #---------------------------------------------------------------------------------
    echo "------------------------------"
fi

cd ..
rm -rf Monday_Testing