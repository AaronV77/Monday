#!/bin/bash

#--------------------------------------------------------------------
#Author: Aaron Anthony Valoroso
#Date: December 17th, 2018
#License: GNU GENERAL PUBLIC LICENSE
#Email: valoroso99@gmail.com
#--------------------------------------------------------------------
# General Explanation:
# The following file is for testing monday and it should be pretty self explanatory. There
# - are two functions; one is cleanup and the other is for when tests fail. Next, I setup 
# - the variables for the script, setup the directory to do the testing in, and then process
# - the incoming parameters. There are to major testing suites and they are the pull and push.
# - Each one can run independently and cleanup. I'm not going to go through each test itself
# - becauce I think the name above each test should explana what it is doing. Lastly, the
# - testing directory is deleted and act like nothing every happened.
#--------------------------------------------------------------------
test_failure() {

    sed -i 's/^/\t/' the_output.txt
    cat the_output.txt
    echo -e "\t----------------------------"
    curr_dir=$(pwd)
    echo -e "\tCurrent Path: $curr_dir"
    echo -e "\t----------------------------"
    echo -e "\tCurrent Directory Contents: "
    ls 1> the_output.txt
    sed -i 's/^/\t/' the_output.txt
    cat the_output.txt        
    echo -e "\t----------------------------"
    rm the_output.txt

}
#--------------------------------------------------------------------
clenaup () {
    cd $HOME
    if [ -d $HOME/Transfer ]; then
        rm -rf $HOME/Transfer
    fi

    if [ -d $HOME/Monday_Testing ]; then
        rm -rf $HOME/Monday_Testing
    fi

    ssh $username@$ip_address -T << EOF
        rm -rf \$HOME/Transfer/*
        cd $storage_location
        if [ -d monday_testing ]; then
            rm -rf monday_testing
        fi
        if [ -d monday_testing_1 ]; then
            rm -rf monday_testing_1
        fi
        if [ -d monday_testing_2 ]; then
            rm -rf monday_testing_2
        fi
        if [ -d test-1 ]; then
            rm -rf test-1
        fi
        if [ -d test-2 ]; then
            rm -rf test-2
        fi
        if [ -f the_test_file.txt ]; then
            rm the_test_file.txt
        fi
        exit
EOF
}
trap cleanup 1 2 3 6 
#--------------------------------------------------------------------
ip_address=None
username=""
storage_location="Documents/storage"
pull_switch=0
push_switch=0
current_directory=$(pwd)

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
    echo "------------------------------"
    echo "Testing - Push.sh"
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Testing adding a just a file."
    touch monday_test.txt
    push monday_test.txt 1> test_output.txt
    results=$(cat test_output.txt | tail -2 | head -1)
    rm test_output.txt
    ssh $username@$ip_address -T 1> the_output.txt << EOF
        outcome=\$(find \$HOME -type f -name monday_test.txt | wc -l)
        if [ \$outcome -eq 1 ]; then
            ls
            cd \$HOME/$storage_location
            rm monday_test.txt
            echo "0"
        elif [ \$outcome -gt 1 ]; then
            echo "1"
        fi
EOF
    outcome=$(cat the_output.txt)
    rm the_output.txt
    if [ "$results" == 'Finished.' ] || [ "$outcome" == '0' ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo -e "\n\t----------------------------"
        push monday_test.txt -error 1> the_output.txt
        test_failure
    fi
    rm monday_test.txt
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Testing adding a directory w/ files."
    mkdir monday_testing
    push monday_testing 1> test_output.txt
    results=$(cat test_output.txt | tail -2 | head -1)
    rm test_output.txt
    ssh $username@$ip_address -T 1> the_output.txt << EOF
        outcome=\$(find \$HOME -type d -name monday_testing | wc -l)
        if [ \$outcome -eq 1 ]; then
            cd \$HOME/$storage_location
            rm -rf monday_testing
            echo "0"
        elif [ \$outcome -gt 1 ]; then
            echo "1"
        fi
EOF

    outcome=$(cat the_output.txt)
    rm the_output.txt
    if [ "$results" == "Finished." ] || [ "$outcome" == "0" ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo -e "\n\t----------------------------"
        push monday_testing -error 1> the_output.txt
        test_failure
    fi
    rm -rf monday_testing
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Testing replacing a directory w/ an added file."
    mkdir monday_testing
    touch monday_testing/example_2222.txt
    push monday_testing 1> test_output.txt
    results=$(cat test_output.txt | tail -2 | head -1)
    rm test_output.txt
    ssh $username@$ip_address -T 1> the_output.txt << EOF
        outcome=\$(find \$HOME -type f -name example_2222.txt | wc -l)
        if [ \$outcome -eq 1 ]; then
            cd \$HOME/$storage_location
            rm -rf monday_testing
            echo "0"
        elif [ \$outcome -gt 1 ]; then
            echo "1"
        fi
EOF

    outcome=$(cat the_output.txt)
    rm the_output.txt
    if [ "$results" == 'Finished.' ] || [ "$outcome" == '0' ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo -e "\n\t----------------------------"
        push monday_testing -error 1> the_output.txt
        test_failure
    fi
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Testing adding two folders at once."
    mkdir test-1 test-2
    push test-1 test2 1> test_output.txt
    results=$(cat test_output.txt | tail -2 | head -1)
    rm test_output.txt
    ssh -T $username@$ip_address 1> the_output.txt << EOF
        outcome=\$(find \$HOME -type d -name test-1 | wc -l)
        if [ \$outcome -eq 1 ]; then
            cd \$HOME/$storage_location
            rm -rf test-1
            outcome=\$(find \$HOME -type d -name test-2 | wc -l)
            if [ \$outcome -gt 1 ]; then
                echo "1"
            else
                rm -rf test-2
                echo "0"
            fi
        elif [ \$outcome -gt 1 ]; then
            echo "1"
        fi
EOF

    outcome=$(cat the_output.txt)
    rm the_output.txt
    if [ "$results" == 'Finished.' ] || [ "$outcome" == '0' ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo -e "\n\t----------------------------"
        push test-1 test2 -error 1> the_output.txt
        test_failure
    fi
    rm -rf test-1 test-2
    echo "------------------"    
    #---------------------------------------------------------------------------------
    echo "Testing adding a folder that has the same name as a file."
    mkdir example_1.txt
    push example_1.txt 1> test_output.txt
    results=$(cat test_output.txt | tail -2 | head -1)
    rm test_output.txt
    ssh -T $username@$ip_address 1> the_output.txt << EOF
        cd \$HOME/$storage_location

        # This is for the next test.
        mkdir blank_1
        touch blank_1/something.txt
        mkdir blank_2
        touch blank_2/something.txt

        if [ -d "example_1.txt" ]; then
            rm -rf example_1.txt
            echo "0"
        else
            echo 1
        fi
EOF

    outcome=$(cat the_output.txt)
    rm the_output.txt
    if [ "$results" == 'Finished.' ] || [ "$outcome" == '0' ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo -e "\n\t----------------------------"
        push example_1.txt -error 1> the_output.txt
        test_failure
    fi
    rm -rf example_1.txt
    echo "------------------"    
    #---------------------------------------------------------------------------------
    echo "Testing updating the correct file."
    mkdir blank_1
    touch blank_1/something.txt
    echo "This has been updated." > blank_1/something.txt
    cd blank_1
    push something.txt 1> ../test_output.txt
    cd ..
    results=$(cat test_output.txt | tail -2 | head -1)
    rm test_output.txt
    ssh -T $username@$ip_address 1> the_output.txt << EOF
        cd \$HOME/$storage_location
        temp=\$(cat blank_1/something.txt)
        if [ "\$temp" == "This has been updated." ]; then
            rm -rf blank_1 blank_2
            echo "0"
        else
            rm -rf blank_1 blank_2
            echo 1
        fi
EOF

    outcome=$(cat the_output.txt)
    rm the_output.txt
    if [ "$results" == 'Finished.' ] || [ "$outcome" == '0' ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo -e "\n\t----------------------------"
        cd blank_1
        push blank_1/something.txt -error 1> ../the_output.txt
        cd ..
        test_failure
    fi
    rm -rf blank_1
    echo "------------------"    
    #---------------------------------------------------------------------------------
    echo "Cleaning Up the Push tests."
    ssh $username@$ip_address -T << EOF
        cd \$HOME/$storage_location
        rm -rf monday_testing
EOF

    rm -rf $current_directory/Monday_Testing/*
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
    pull monday_testing_1 1> the_output.txt
    outcome=$(cat the_output.txt | tail -2 | head -1)
    rm the_output.txt
    directory=$(ls)
    if [ "$directory" == "monday_testing_1" ] && [ "$outcome" == 'Finished.' ]; then
        echo "PASSED"
    else
        echo "FAILED"
        pull monday_testing_1 -error 1> the_output.txt
        test_failure
    fi
    rm -rf monday_testing_1
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Pulling an empty directory."
    pull monday_testing_2 1> the_output.txt
    outcome=$(cat the_output.txt | tail -2 | head -1)
    rm the_output.txt
    directory=$(ls)
    if [ "$directory" == "monday_testing_2" ] && [ "$outcome" == 'Finished.' ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo -e "\n\t----------------------------"
        pull monday_testing_2 -error 1> the_output.txt
        test_failure
    fi
    rm -rf monday_testing_2
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Pulling a file."
    pull the_test_file.txt 1> the_output.txt
    outcome=$(cat the_output.txt | tail -2 | head -1)
    rm the_output.txt
    directory=$(ls)
    if [ "$directory" == "the_test_file.txt" ] && [ "$outcome" == 'Finished.' ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo -e "\n\t----------------------------"
        pull the_test_file.txt -error 1> the_output.txt
        test_failure
    fi
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Pulling a file thats already on the system."
    first_stamp=$(stat --printf=%y the_test_file.txt | cut -d. -f1)
    sleep 5
    ssh -T $username@$ip_address << EOF
        echo "This is something extra" 1> \$HOME/$storage_location/the_test_file.txt
EOF

    pull the_test_file.txt 1> the_output.txt
    outcome=$(cat the_output.txt | tail -2 | head -1)
    rm the_output.txt
    second_stamp=$(stat --printf=%y the_test_file.txt | cut -d. -f1)
    if [ "$first_stamp" == "$second_stamp" ] || [ "$outcome" != 'Finished.' ]; then
        echo "FAILED"
        echo -e "\t----------------------------"
        pull the_test_file.txt -error 1> the_output.txt
        test_failure
    else
        echo "PASSED"
    fi
    rm the_test_file.txt
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Pulling a file that is on the server twice."
    ssh $username@$ip_address -T << EOF
        cd \$HOME/$storage_location
        touch monday_testing_2/the_test_file.txt
EOF
    pull the_test_file.txt 1> the_output.txt
    outcome=$(cat the_output.txt | tail -1)
    rm the_output.txt
    if [ "$outcome" == 'Exiting...' ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo -e "\t----------------------------"
        pull the_test_file.txt -error 1> output.txt
        test_failure
    fi
    echo "------------------"
    #---------------------------------------------------------------------------------
    echo "Pulling two folders."
    pull monday_testing_1 monday_testing_2 -test 1> the_output.txt
    outcome=$(cat the_output.txt | tail -2 | head -1)
    rm the_output.txt
    directory_contents=$(ls | wc -l)
    if [ "$directory_contents" == "2" ] && [ "$outcome" == "Finished." ]; then
        echo "PASSED"
    else
        echo "FAILED"
        echo -e "\t----------------------------"
        pull monday_testing_1 monday_testing_2 -error 1> the_output.txt
        test_failure
    fi
    rm -rf monday_testing_1
    rm -rf monday_testing_2
    echo "------------------"    
    #---------------------------------------------------------------------------------
    echo "Cleaning Up the Pull tests."
    ssh $username@$ip_address -T << EOF
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