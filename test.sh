#!/bin/sh

ip_address=None
username=""
storage_location="/home/valorosoa/Documents/storage"

mkdir Monday_Testing
cd Monday_Testing
mkdir monday_testing
touch monday_testing/example_1.txt
touch monday_testing/example_2.txt


# Add tests:
#   - Try pushing a single file and an empty directory.

echo "------------------------------"
echo "Testing - Push.sh"
echo "------------------"
#---------------------------------------------------------------------------------
echo "Testing adding a directory w/ files."
results=$(push monday_testing -test)
ssh -T $username@$ip_address > output.txt << EOF
    outcome=\$(find \$HOME/Transfer | wc -l)
    if [ \$outcome -gt 1 ]; then
        echo "1"
    else 
        echo "0"
    fi
EOF
outcome=$(cat output.txt)
if [ "$results" == "0" ] || [ "$outcome" == "0" ]; then
    echo "PASSED"
else
    echo "FAILED"
fi
echo "------------------"
#---------------------------------------------------------------------------------
echo "Testing replacing a directory w/ an added file."
touch monday_testing/example_2.txt
results=$(push monday_testing -test=on)
ssh -T $username@$ip_address > output.txt << EOF
    outcome=\$(find \$HOME/Transfer | wc -l)
    if [ \$outcome -gt 1 ]; then
        echo "1"
    else 
        echo "0"
    fi
EOF
outcome=$(cat output.txt)
if [ "$results" == '0' ] || [ "$outcome" == '0' ]; then
    echo "PASSED"
else
    echo "FAILED"
fi
echo "------------------"
#---------------------------------------------------------------------------------
echo "Testing adding a directory with more than one location."
ssh -T $username@$ip_address > output.txt << EOF
    cd $storage_location
    mkdir second_testing
    mkdir second_testing/monday_testing
EOF
results=$(push monday_testing -test)
if [ "$results" == '1' ]; then 
    echo "PASSED"
else
    echo "FAILED"
fi
echo "------------------"
#---------------------------------------------------------------------------------
echo "Testing adding an empty directory."
rm monday_testing/*
results=$(push monday_testing -test)
ssh -T $username@$ip_address > output.txt << EOF
    outcome=\$(find \$HOME/Transfer | wc -l)
    if [ \$outcome -gt 1 ]; then
        echo "1"
    else 
        echo "0"
    fi
EOF
outcome=$(cat output.txt)
if [ "$results" == '0' ] || [ "$outcome" == '0' ]; then
    echo "PASSED"
else
    echo "FAILED"
fi
echo "------------------"
#---------------------------------------------------------------------------------
echo "Testing adding a just a file."
rm -rf monday_testing
touch monday_test.txt
results=$(push monday_test.txt -test)
ssh -T $username@$ip_address > output.txt << EOF
    outcome=\$(find \$HOME/Transfer | wc -l)
    if [ \$outcome -gt 1 ]; then
        echo "1"
    else 
        echo "0"
    fi
EOF
outcome=$(cat output.txt)
if [ "$results" == '0' ] || [ "$outcome" == '0' ]; then
    echo "PASSED"
else
    echo "FAILED"
fi
echo "------------------"
#---------------------------------------------------------------------------------
echo "Cleaning Up the Push tests."
ssh -T $username@$ip_address > output.txt << EOF
    cd $storage_location
    rm -rf monday_testing
    rm -rf second_testing
    rm monday_test.txt
EOF
rm output.txt
rm monday_test.txt
#---------------------------------------------------------------------------------
echo "------------------------------"
echo ""

ssh -T $username@$ip_address << EOF
    cd $storage_location
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
    rm -rf *
else
    echo "FAILED"
fi
echo "------------------"
#---------------------------------------------------------------------------------
echo "Pulling an empty directory."
outcome=$(pull monday_testing_2 -test)
directory=$(ls)
if [ "$directory" == "monday_testing_2" ] && [ "$outcome" == 0 ]; then
    echo "PASSED"
    rm -rf *
else
    echo "FAILED"
fi
echo "------------------"
#---------------------------------------------------------------------------------
echo "Pulling a file."
outcome=$(pull the_test_file.txt -test)
directory=$(ls)
if [ "$directory" == "the_test_file.txt" ] && [ "$outcome" == 0 ]; then
    echo "PASSED"
else
    echo "FAILED"
fi
echo "------------------"
#---------------------------------------------------------------------------------
echo "Pulling a file thats already on the system."
first_stamp=$(stat --printf=%y the_test_file.txt | cut -d. -f1)
sleep 5
ssh -T $username@$ip_address << EOF
    echo "This is something extra" > $storage_location/the_test_file.txt
EOF
outcome=$(pull the_test_file.txt -test)
second_stamp=$(stat --printf=%y the_test_file.txt | cut -d. -f1)
if [ "$first_stamp" == "$second_stamp" ]; then
    echo "FAILED"
else
    echo "PASSED"
fi
echo "------------------"
#---------------------------------------------------------------------------------
echo "Pulling a file that is on the server twice."
ssh -T $username@$ip_address > output.txt << EOF
    cd $storage_location
    touch monday_testing_2/the_test_file.txt
EOF
outcome=$(pull the_test_file.txt -test)
if [ "$outcome" == 1 ]; then
    echo "PASSED"
else
    echo "FAILED"
fi
echo "------------------"

#---------------------------------------------------------------------------------
echo "Cleaning Up the Pull tests."
ssh -T $username@$ip_address > output.txt << EOF
    cd $storage_location
    rm -rf monday_testing_1
    rm -rf monday_testing_2
    rm the_test_file.txt
EOF
#---------------------------------------------------------------------------------
echo "------------------------------"

cd ..
rm -rf Monday_Testing
