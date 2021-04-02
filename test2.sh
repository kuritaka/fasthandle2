#!/bin/sh

cmd_whoami(){
    whoami
}

uname_n(){
    uname -n
}

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

