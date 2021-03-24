# FastHandle 2 - Deploy Tool like Python Fabric

## What is FastHandle 2?

FastHandle is tools to make infrastructure construction operations and test operations more efficient.  
FastHandle will make your operation faster and more accurate.  
And FastHandle aims to improve Linux knowledge by looking at settings and commands on the official site.  
  
https://fasthandle.net/


## What is difference between FastHandle 1 and FastHandle 2

In FastHandle 1, I used python fabric.

In FastHandle 2, I make fh.sh like python fabric,
Because it is easy to use such as options. 

## FastHandle Characteristic

* Simple
  * Less learning cost
  * start using FastHandle right away
* Extreme efficiency
  * Quick setup and testing
* Mangage from 1 server to over 1,000 servers
* Agentless
* Knowledge Base for Linux Configuration , Testing and Operation 
  * You acquire knowledge that you can make use of whichever company you go to.


## How to use fh
```
$ fh -h
Usage: ./fh.sh  [options]

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
  fh.sh -c uname -n
  fh.sh -s script/test1.sh
  fh.sh -s script/test1.sh:arg1,arg2 script/test2.sh:arg1,arg2
  fh.sh -o outputfile -c uname -n
  fh.sh -o -c uname -n   # default outputfile

Example Remote:
  fh.sh -H host1 -c uname -n
  fh.sh -H host1,host2 -c uname -n
  fh.sh -H host1,host2 -s script/test.sh:uname_n
  fh.sh -H hostlist -s script/test.sh:uname_n
```


## Best Practices

### Directory Layout
```
$ tree
.
|-- README.md
|-- bin
|-- config
|-- deb
|-- fhscripts
|   |-- fh.env
|   `-- fh.sh
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



