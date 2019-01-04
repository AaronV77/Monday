# Monday

Monday? What is Monday you are asking? Monday is a package of scripts in order to push and pull from a cental storage location. A little background. I have always used GitHub repo's as a central means of storing anything that I wanted to share among my other computers. No More! I had extra computer hardware laying around to setup a simple server to recieve ssh communication (port 22), and created these scripts to mimic the workings of git pull and git push. Now all you have to do is type push "file or directory" or pull "file or directory. Simple huh?

The two main scripts that I have took some black magic to pull off, but I have provided a lot of comments to explain what I did and why I did it. There is also a fair bit of setup that you have to do in each script, such as username, ip_address, storage location on your server, and router setup. These are important or this whole process will not work at all. So, please read through all the scripts so that they make sense to you and are setup correctly, or you will get unexpected results.

A couple last little details to mention before I go. First, I am no daily scripter, so if you see anything that could be done differently, then by all means I'll take any comments or PR's. Second, it would be super helpful if you setup your ssh keys before trying to get this package to work between your client and server. There are two password entries needed for each script, and ten for the tests. So, all that typing can get rather annoying. Lastly, I hope you enjoy my package of scripts here, and that you contribute if you find a better way of doing things. Thanks~!

## Getting Started

Just follow the upcoming sections they should make startup very clear.

## Warnings

Since these are bash scripts, please make sure to always check any scripts that you are going to run on your system! Also every machine is setup differently and I would hate for these scripts to overwrite any precious keys or any other information. So please, make sure to understand how these scripts are working and what they are doing. There is enough documentation in the files to make the learning transition faster.

## Prerequisites

The only prerequisites is that you need to use the Bash shell on your system in order to be able to use the scripts. I have not supported the other shells yet and have only gotten this package to work with Bash. Lastly, your clients and server have to be some type of Linux Distro and they do not have to be of the same distro.

## Installing

Just run the setup.sh script in the package directory. There will be stuff that you have to do manually on your server for this package to work as anticipated and thats just editing the ssh config file. Just follow the setup.sh prompt. If you would like to develop the code then run the setup script like so: ./setup.sh -develop. This will setup a directory in your home directory called .monday and you should be able to see where everything is at from there.

## Testing

There is a test script included into the source for checking if your installation is working or if any changes that you have implemented are working. You will have to run it in the following manner: "source ./test.sh". Now I don't know if every shell supports the command "source" so again these scripts will only work in bash as of right now. Add more tests if you see anything that I am missing.

## Help
Every script that you are able to run in this package has a -h or --help feature that will give you a usage that should be more helpful with all the avalable arguments that eah script can take.

## Contributing

Like I've said in the previous sections I hope that people get to use these scripts and contribute. Before submitting a PR, I've written a script call credential scan to remove any credentials that you could be stored in the scripts. There is a specific thing that the script is looking for so don't go stashing your IP address or Username anywhere else than needed. This will save a lot of hassel.. trust me, so run the script. 

# Author: Aaron A. Valoroso


## Inspiring Quotes

I choose a lazy person to do a hard job. Because a lazy person will find an easy way to do it.
 
 - Bill Gates
