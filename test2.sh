#!/bin/sh

#fh -H host1 -f test2.sh:cmd_whoami
cmd_whoami(){
    whoami
}

#fh -H host1 -f test2.sh:uname_n
uname_n(){
    uname -n
}


#fh -H host1 -f test2.sh:ip_a
ip_a(){
    ip a
}


#FastHandle Function
if [ "$#" -ne 0 ]; then
    for ARG in "$@"
    do
        $ARG
    done
else
    #execute all function
    ALL_FUNCTION=$(cat $0 |grep "()" |grep -v "ALL_FUNCTION" |awk -F\( '{ print $1 }')
    $ALL_FUNCTION
fi

