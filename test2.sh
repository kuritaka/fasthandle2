#!/bin/sh
#fh -H host1 -f test1.sh:argall


#fh -H host1 -f test1.sh:cmd_whoami
cmd_whoami (){
    whoami
}

#fh -H host1 -f test1.sh:uname_n
uname_n (){
    uname -n
}

#fh -H host1 -f test1.sh:ip_a
ip_a (){
    ip a
}



#==============================================
#FastHandle Function
#==============================================
#execute all function
execute_all (){
    ALL_FUNCTION=$(cat $0 |grep -e "(\s*)\s*{" |egrep -v "execute_all|ALL_FUNCTION" |awk -F\( '{ print $1 }')
    for ARG in $(echo $ALL_FUNCTION)
    do
        $ARG
    done    
}

if [ "$#" -ne 0 ] ; then
    for ARG in "$@"
    do
        if [ "$ARG" == "argall" ] ; then
            #execute all function
            execute_all
        else
            $ARG
        fi
    done
else
    #execute all function
    execute_all
fi
