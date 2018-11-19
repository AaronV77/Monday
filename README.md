# Monday

Monday? What is Monday you are asking? Monday is a package of scripts in order to push and pull from a cental storage location. A little background. I have always used GitHub repo's as a central means of storing anything that I wanted to share among my other computers. No More! I had extra computer hardware laying around to setup a simple server to recieve ssh communication (port 22), and created these scripts to mimic the workings of git pull and git push. Now all you have to do is type push "file or directory" or pull "file or directory. Simple huh?

The two main scripts that I have took some black magic to pull off, but I have provided a lot of comments to explain what I did and why I did. There is also a fair bit of setup that you have to do in each script, such as username, ip_address, and storage location on your server. These are important or this whole process will not work at all. So, please read through all the scripts so that they make sense to you and are setup correctly, or you will get unexpected results.

A couple last little details to mention before I go. First, I am no daily scripter, so if you see anything that could be done differently then by all means I take any comments or PR's. Second, it would be super helpful if you setup your ssh keys before trying to get this package to work between your client and server. There are at least three password entries needed for each script, and that can get rather annoying. Third, there are some weird workings in bash that when I created my function in order to call push or pull, the scritps would not work if I did not have bash /path/to/file, but they are shell scripts not bash. So, ya I don't know. Lastly, I hope you enjoy my package scripts here, and that you contribute if you find a better way of doing things. Thanks~!

## Getting Started

Just follow the upcoming sections they should make startup very clear.

## Warnings

Since these are shell scripts please make sure to always check any shell scripts that you are going to run on your system! Also every machine is setup differently and I would hate for these scripts to overwrite any precious keys or any other information. Lastly, I have not fully tested the setup.sh script to make sure that it works as expected, and so use this file with hesitation.

## Prerequisites

The only prerequisites is that you need to use the Bash bourne shell in order to be able to call the scripts from any where. I have not supported the other shells yet and have only gotten this package to work with Bash.

## Installing

Just run the setup.sh script in the directory. I have not tested this script fully, so please just follow the commands by hand. Once done you can then use the commands push and pull with an argument.


# Author: Aaron A. Valoroso


## Inspiring Quotes

I choose a lazy person to do a hard job. Because a lazy person will find an easy way to do it.
 
 - Bill Gates
