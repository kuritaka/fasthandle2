# FastHandle 2 - Deploy Tool like Python Fabric

## What is FastHandle?

FastHandle is tools to make infrastructure construction operations and test operations more efficient.  
FastHandle will make your operation faster and more accurate.  
And FastHandle aims to improve Linux knowledge by looking at settings and commands on the official site.  
  

## What is difference between FastHandle 1 and FastHandle 2

In FastHandle 1, I mainly used python fabric.
And Fasthandle 1 is best practice for python fabric.

But in FastHandle 2, I make fh command. It works like python fabric.
And I was improving it to make it easier to use.


## Features

* Simple
  * Less learning cost
  * Quick setup 
* Low environmental dependence
* Agentless
* Extreme efficiency
* Mangage from 1 server to over 1,000 servers
* Knowledge Base for Linux Configuration , Testing and Operation 
  * You acquire knowledge that you can make use of whichever company you go to.


## Setup
### What to do if you have root privileges 
```
~]$ curl -o fh https://raw.githubusercontent.com/kuritaka/fasthandle2/main/fhscripts/fh.sh
~]$ chmod 755 fh
~]$ sudo mv  -i fh  /usr/local/bin/

~]$ which fh
/usr/local/bin/fh
~]$ fh -h
```


### How to do with user privileges 
```
~]$ cd /home/$USER
~]$ mkdir bin
~]$ cd bin
~]$ curl -o fh https://raw.githubusercontent.com/kuritaka/fasthandle2/main/fhscripts/fh.sh
~]$ chmod 755 fh
~]$ export PATH="$PATH:/home/$USER/bin:." >>  .bashrc
~]$ exit

#login
~]$ fh -h
```


### Configuration
fh command work without configuration.

If you want to change configuration, you can use .fhrc of USER Home Directory or fh.conf of fh command directory or /etc/fh.conf.
If there are multiple parameters, USER Home Directory's hf.conf is used.
If there are fh.conf of fh command directory or /etc/fh.conf, fh.conf of fh command directory is used.

/etc/fh.conf --> ${SCRIPTDIR}/fh.conf --> ~/.fhrc

```
~]$ cd /etc
~]$ curl -O https://raw.githubusercontent.com/kuritaka/fasthandle2/main/fhscripts/fh.conf

or

~]$ cd /home/$USER
~]$ curl -o .fh.conf https://raw.githubusercontent.com/kuritaka/fasthandle2/main/fhscripts/fh.conf
```



## Usage
```
$ fh -h
Usage: fh  [options]

Options:
    -h, --help              show this help message and exit
    --version               show program's version number and exit
    -v, --verbose           verbose mode
    -d, --debug             debug mode
    -H HOST1[,HOST2], --hosts=HOST1[,HOST2], -H HOSTLISTFILE, --hosts=HOSTLISTFILE
                            comma-separated list of hosts or <HOSTLISTFILE> to operate on
    -o OUTPUTFILE, --output=OUTPUTFILE
                            Write output to bouth stdout and <OUTPUTFILE>
    -- COMMAND, -c COMMAND, --command=COMMAND
                            Execute COMMAND
    -f SHELLSCRIPT, --file=SHELLSCRIPT
                            Execute ShellScript

  Connection Options:
    control as whom and how to connect to hosts

    -u USER, --user=USER    username to use when connecting to remote hosts
    -p, -p PASSWORD, --password, --password=PASSWORD
                            ssh password
                            If you do not specify a password, an input field will appear. 
    -i PRIVATEKEY           SSH private key file.
    -P PORT, --port=PORT    Port to connect to on the remote host.


Usage:
  Execute in Local Host:
    fh -c uname -n
    fh -f test1.sh
    fh -f test1.sh:arg1,arg2 test2.sh:arg1,arg2
    fh -o outputfile -c uname -n

  Execute in Remote Host:
    fh -H host1 -c uname -n
    fh -H host1,host2 -c uname -n
    fh -H host1,host2 -f test1.sh
    fh -H hostlist -f test1.sh
    fh -H host1 -o outputfile -c uname -n
```


## Dependencies
* bash
* ssh
* scp
* sshpass



## License
This software is released under the MIT License, see LICENSE.

## Authors
Takaaki Kurihara
