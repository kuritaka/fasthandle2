# FastHandle 2 - Deploy Tool like Python Fabric

## What is FastHandle?

FastHandle is tools to make infrastructure construction operations and test operations more efficient.  
FastHandle will make your operation faster and more accurate.  
And FastHandle aims to improve Linux knowledge by looking at settings and commands on the official site.  
  
https://fasthandle.net/


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
~]$ sudo mv  -i fh  /bin/
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
fh command work without fh.conf.

If you want to change configuration, you can use fh.conf.
fh command read fh.conf from USER Home Directory or fh command directory.
If there are multiple parameters, USER Home Directory's hf.conf is use.

```
~]$ cd /home/$USER
~]$ curl -O https://raw.githubusercontent.com/kuritaka/fasthandle2/main/fhscripts/fh.conf
```



## Usage
```
$ fh -h
Usage: ./fh  [options]

Options:
    -h, --help              show this help message and exit
    --version               show program's version number and exit
    -v, --verbose           verbose mode
    -H HOST, --hosts=HOST   
    -H HOST1,HOST2, --hosts=HOST1,HOST2
    -H FILE
                            comma-separated list of hosts to operate on
    -o [OUTPUTFILE]           Write output to <file> instead of stdout
    -c COMMAND, --command=COMMAND
                            Execute COMMAND
    -s SHELLSCRIPT          Execute ShellScript

  Connection Options:
    control as whom and how to connect to hosts

    -u USER, --user=USER    username to use when connecting to remote hosts
    -i PRIVATEKEY           SSH private key file.


Example Local:
  fh -c uname -n
  fh -s script/test1.sh
  fh -s script/test1.sh:arg1,arg2 script/test2.sh:arg1,arg2
  fh -o outputfile -c uname -n
  fh -o -c uname -n   # default outputfile

Example Remote:
  fh -H host1 -c uname -n
  fh -H host1,host2 -c uname -n
  fh -H host1,host2 -s script/test.sh:uname_n
  fh -H hostlist -s script/test.sh:uname_n
```


## Dependencies
* bash
* ssh
* scp



## Best Practices

https://github.com/kuritaka/fasthandle2-best-practices

### Directory Layout
```
$ tree
.
|-- README.md
|-- bin
|-- config
|-- deb
|-- hosts
|   `-- hostlist
|-- key
|-- log
|-- rpm
|-- script
|   |-- check_centos7.sh
|   |-- test.sh
|   `-- test.txt
|-- src
`-- work
```


## License
This software is released under the MIT License, see LICENSE.

## Authors
Takaaki Kurihara
