#!/bin/bash
#=============================================================
# Script name : fh (FastHandle)
# Description : deploy tool like python fabric
# Author      : Takaaki Kurihara
# Refarence:
# https://github.com/kuritaka/fasthandle2
#
VERSION="2.2021.04.02a Beta"

usage_exit() {
cat <<HELP
Usage: fh  [options]

Options:
    -h, --help                  show this help message and exit
    --version                   show program's version number and exit
    -v, --verbose               verbose mode
    -d, --debug                 debug mode
    -H HOST1[,HOST2], --hosts=HOST1[,HOST2], -H HOSTLISTFILE, --hosts=HOSTLISTFILE
                                comma-separated list of hosts or <HOSTLISTFILE> to operate on
    -o OUTPUTFILE, --output=OUTPUTFILE
                                Write output to bouth stdout and <OUTPUTFILE>
    -s, --sudo                  Execute command or shellscript with sudo
    -- COMMAND, -c COMMAND, --command=COMMAND
                                Execute COMMAND
    -f SHELLSCRIPT, --file=SHELLSCRIPT, -f SHELLSCRIPT1 SHELLSCRIPT2
                                Execute ShellScript
    --ping                      check ping test
    --login                     login remote host
    --vi FILE, --vi=FILE        edit the remote file with vi
    --nano FILE, --nano=FILE    edit the remote file with nano
    --scp LOCLA_FILE REMOTE_DIR
                                transport file with scp

  Connection Options:
    control as whom and how to connect to hosts

    -u USER, --user=USER        username to use when connecting to remote hosts
    -p, --password, -p PASSWORD, --password=PASSWORD
                                ssh password
                                If you do not specify a password, an input field will appear. 
    -i PRIVATEKEY               SSH private key file.
    -P PORT, --port=PORT        Port to connect to on the remote host.


Usage:
  Execute Commnad in Local Host:
    fh -c uname -n
    fh -c 'uname -n; whoami'
    fh -c 'echo \$(uname -n)-------; whoami'
    fh -c whoami
    fh -c 'sudo whoami'
    fh -s -c whoami

  Execute ShellScript in Local Host:
    fh -f test.sh
    fh -f test.sh:cmd_whoami,uname_n
    fh -f test.sh:cmd_whoami,uname_n test2.sh:arg1,arg2
    fh -o outputfile -c uname -n

  Execute Command in Remote Host:
    fh -H host1 -c uname -n
    fh -H host1 -s -c whoami
    fh -H host1 -c sudo whoami
    fh -H host1 -c 'uname -n; whoami'
    fh -H host1 -c 'sudo uname -n; sudo whoami'
    fh -H host1 -s -c 'uname -n; whoami'
    fh -H host1 -c 'echo \$(uname -n)--------; whoami'
    fh -H host1 -s -c 'echo \$(uname -n)--------; whoami'
    fh -H host1,host2 -c uname -n
    fh -H host1,host2 -s -c uname -n

  Execute ShellScript in Remote Host:
    fh -H host1 -f test.sh:cmd_whoami
    fh -H host1 -s -f test.sh:cmd_whoami
    fh -H host1,host2 -f test.sh
    fh -H hostlist -f test.sh:cmd_whoami
    fh -H host1 -o outputfile -c uname -n

  Others
    fh -H host1 --ping
    fh -H host1 --login
    fh -H host1 --vi FILE
    fh -H host1 --nano FILE
    fh -H host1 -s --vi FILE   #-s = with sudo
    fh -H host1 --scp LOCAL_FILE  REMOTEDIR
HELP
}
#=============================================================

PROGNAME=$(basename $0)
SCRIPTDIR=$(cd $(dirname $0); pwd)

#Default parameters
REMOTEWORK="/tmp"

# /etc/fh.conf --> ${SCRIPTDIR}/fh.conf --> ${HOME}/fh.conf --> ${HOME}/.fhrc
[ -f "/etc/fh.conf" ] && source /etc/fh.conf
[ -f "${SCRIPTDIR}/fh.conf" ]  && source ${SCRIPTDIR}/fh.conf
[ -f "${HOME}/fh.conf" ] &&  source ${HOME}/fh.conf
[ -f "${HOME}/.fhrc" ] &&  source ${HOME}/.fhrc

[ ! -z ${SSHUSER} ] && USERAT="${SSHUSER}@"
[ ! -z ${SSHPASS} ] && SSHPASSP="sshpass -p ${SSHPASS}"
[ ! -z ${SSHKEY} ] && SSHKEY="-i ${SSHKEY}"



#Function
host_parce(){
    #hostlist:arg1,arg2
    ARG1=$(echo $ARGHOST |awk  -F: '{ print $1}')
    GROUP=$(echo $ARGHOST |awk  -F: '{ print $2}' |sed -e 's/,/|/g' )

    #Check File
    if [ -f "$ARG1" ]; then
        HOST=$(egrep -v "^#" $ARG1 |egrep "$GROUP" | awk  '{ print $1}')
    else
        H=`echo $ARGHOST | tr "," " "`
        HOST=`echo $H`
    fi

    echo "HOST : $(echo $HOST)"
}

pass_parce(){
    read -sp "ssh password:" PASS
    echo ""
    SSHPASSP="sshpass -p $PASS"
}

out_parce(){
    if [ -z "${OUT}" ] ; then
        echo "[Critical Message] output file is null"
        exit 1
    else
        if [ -f "${OUT}" ]  ; then
            echo ""
            echo -n -e "File ${OUT}  already exits. Overwrite? [y/n]"
            read NUM
            case ${NUM} in
              y|Y) cp /dev/null "${OUT}"
                   ;;
              n|N) echo "quit"
                   exit 1
                   ;;
              *) echo "exit : no selection is missed."
                 exit 1
                 ;;
            esac
        fi

        OUTFILE="${OUT}"
    fi
    #OUTTEE=" 2>&1 | tee -a $OUTFILE"

    echo "LOG : $OUTFILE"
}

command_parce(){
    #echo "COMMAND before = $COMMAND"
    echo "COMMAND = $COMMAND"

    COMMAND=$(echo $COMMAND | sed 's/"/\\"/g')

}

file_parce(){
    #echo "file_parce : $FILE"

    for i in $FILE
    do
        F=$(echo $i | awk -F: '{ print $1 }')

        #Check File
        #echo "check file : $F"
        if [ ! -f "$F" ]; then
            echo "ERROR : not find $F"
            exit 1
        fi

        SHELLNAME=$(basename $F)
        SHELLDIR=$(cd $(dirname $F); pwd)

        FILES=$(echo $FILES $F)

        #create uniq file
        arr=($FILES)
        FILE_UNIQ=$( printf "%s\n" "${arr[@]}" | sort -u )


        #Check Arg
        A=$(echo $i | awk -F: '{ print $2 }')


        if [ -z "$HOST" ] ; then
            #Local Host
            if [ -z "$A" ] ; then
                arrays+=("$F")
            else
                #echo "ARGS = $A"
                ARGS=$(echo $A | tr "," " ")
                #echo "ARGS = $ARGS"

                for args in $(echo $ARGS)
                do
                    #echo "for args : $args"
                    arrays+=("${SHELLDIR}/${SHELLNAME} $args")
                    #echo "COMMAND : $F  $args"
                    echo "COMMAND : ${SHELLDIR}/${SHELLNAME}  $args"
                done

                #ENDA=$(echo $ENDA $A)
                #echo $ENDA
            fi
        else
            #Remote Host
            if [ -z "$A" ] ; then
                SHELL=$(basename $F)
                arrays+=("$SHELL")
            else
                #echo "ARGS = $A"
                ARGS=$(echo $A | tr "," " ")
                #echo "ARGS = $ARGS"

                for args in $(echo $ARGS)
                do
                    #echo "for args : $args"
                    SHELL=$(basename $F)
                    arrays+=("$SHELL $args")
                done

                #ENDA=$(echo $ENDA $A)
                #echo $ENDA
            fi
        fi
    done

}


option_parce(){
    while [ "$#" -gt 0 ]
    do
        #echo '$1' " = $1 : ALL ARGS =  $@"
        case $1 in
            -h | --help)
                usage_exit
                exit 1
                ;;
            -V | --version)
                echo $VERSION
                exit 1
                ;;
            -v | --verbose)
                VERV_FLAG="true"
                ;;
            -d | --debug)
                DEBUG_FLAG="true"
                ;;
            -i )
                SSHKEYI="-i $2"
                shift
                ;;
            -s | --sudo)
                SUDOMODE="sudo"
                ;;
            -u | --user*)
                if [[ "$1" =~ "--user=" ]] ; then
                    SSHUSER=$(echo $1 | awk -F= '{ print $2 }')
                else
                    SSHUSER="$2"
                    shift
                fi
                USERAT="$SSHUSER@"
                ;;
            -p | --password*)
                if [[ "$1" =~ "--password" ]] ; then
                    if [[ "$1" =~ "--password=" ]] ; then
                        #--password PASSWORD
                        SSHPASSP=$(echo $1 | awk -F= '{ print "sshpass -p "$2 }')
                    else
                        #--password only
                        pass_parce
                    fi
                else
                    if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                        #-p only
                        pass_parce
                    else
                        #-p PASSWORD
                        SSHPASSP="sshpass -p $2"
                        shift
                    fi
                fi
                ;;
            -P | --port*)
                if [[ "$1" =~ "--port=" ]] ; then
                    SSHPORT=$(echo $1 | awk -F= '{ print $2 }')
                else
                    SSHPORT="$2"
                    shift
                fi
                ;;
            -H | --hosts*)
                if [[ "$1" =~ "--hosts=" ]] ; then
                    ARGHOST=$(echo $1 | awk -F= '{ print $2 }')
                else
                    ARGHOST="$2"
                    shift
                fi
                host_parce
                ;;
            -o | --output*)
                #echo '$2' = "$2"
                if [[ "$1" =~ "--output" ]] ; then
                    if [[ "$1" =~ "--output=" ]] ; then
                        #echo "--output="
                        OUT=$(echo $1 | awk -F= '{ print $2 }')
                    else
                        #echo "--output only"
                        out_parce
                    fi
                else
                    if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                        #echo "-o only"
                        out_parce
                    else
                        #echo "-o $2"
                        OUT="$2"
                        out_parce
                        shift
                    fi
                fi
                ;;
            -c | --command* | -- ) 
                if [[ "$1" =~ "--command=" ]] ; then
                    COMMAND=$(echo $* | awk -F= '{ {for(i=2;i<NF;i++)printf("%s ",$i) }print($NF) }')
                    command_parce
                else
                    shift
                    COMMAND="$*"
                    command_parce
                fi
                break
                ;;
            -f | --file* )
                if [[ "$1" =~ "--file=" ]] ; then
                    FILE=$(echo $1 | awk -F= '{ {for(i=2;i<NF;i++)printf("%s ",$i) }print($NF) }')
                    file_parce
                else
                    shift
                    FILE="$*"
                    #echo "FILE $FILE"
                    file_parce
                fi
                break
                ;;
            --ping)
                PING_FLAG="true"
                ;;
            --login | --ssh)
                LOGIN_FLAG="true"
                ;;
            --vi*)
                VI_FLAG="true"
                if [[ "$1" =~ "--vi=" ]] ; then
                    #--vi=FILE
                    REMOTEFILE=$(echo $1 | awk -F= '{ print $2 }')
                else
                    #--vi FILE
                    REMOTEFILE="$2"
                    shift
                fi
                ;;
            --nano*)
                NANO_FLAG="true"
                if [[ "$1" =~ "--nano=" ]] ; then
                    #--nano=FILE
                    REMOTEFILE=$(echo $1 | awk -F= '{ print $2 }')
                else
                    #--nano FILE
                    REMOTEFILE="$2"
                    shift
                fi
                ;;
            --scp)
                SCP_FLAG="true"
                #--scp LOCAL_FILE REMOTE_DIR
                SCP_LOCAL_FILE="$2"
                SCP_REMOTE_DIR="$3"
                shift
                shift
                ;;
            -*) 
                echo ""
                echo "$0: illegal option $1"
                echo ""
                echo ""
                usage_exit
                exit 1
                ;;
            *)
                echo ""
                echo "$0: illegal option $1"
                echo ""
                echo ""
                usage_exit
                exit 1
                ;;
        esac
        shift
done
}

#Option Sort
while [ "$#" -gt 0 ]
do
    #echo '$1' " = $1 : ALL ARGS =  $@"
    case $1 in
        -H | --hosts*)
            if [[ "$1" =~ "--hosts=" ]] ; then
                OPTION1+=" $1 "
            else
                OPTION1+=" $1  $2 "
                shift
            fi
            ;;
        *)
            OPTION2+=" $1 "
            ;;
    esac
    shift
done

OPTION="$OPTION1 $OPTION2"
option_parce $OPTION


echo ""
if [ "$VERV_FLAG" == "true" ] ; then
    ECHO="on"
    SSHVERV=""
    BASHVERV=""
elif [ "$DEBUG_FLAG" == "true" ] ; then
    ECHO="on"
    SSHVERV="-v"
    BASHVERV="-x"
else
    SSHVERV="-q"
    BASHVERV=""
fi



#Execute in Local Host
if [ -z "${HOST}" ]; then
    if [ -z "${FILE}" ] ; then
        #Execute Command
        if [ -z "${OUTFILE}" ] ; then
            [ "$ECHO" == "on" ] && echo "Execute : ${SUDOMODE} bash ${BASHVERV} -c \"${COMMAND}\""
            ${SUDOMODE} bash ${BASHVERV} -c "${COMMAND}"
        else
            [ "$ECHO" == "on" ] && echo "Execute : ${SUDOMODE} bash ${BASHVERV} -c \"${COMMAND}\" 2>&1 | tee -a \"${OUTFILE}\""
            ${SUDOMODE} bash ${BASHVERV} -c "${COMMAND}" 2>&1 | tee -a "${OUTFILE}"
        fi
    else
        #Execute Shell
        for array in "${arrays[@]}"
        do
            if [ -z "${OUTFILE}" ] ; then
                [ "$ECHO" == "on" ] && echo "Execute : ${SUDOMODE} bash ${BASHVERV} ${array}"
                ${SUDOMODE} bash ${BASHVERV} ${array}
            else
                [ "$ECHO" == "on" ] && echo "Execute : ${SUDOMODE} bash ${BASHVERV} ${array}  2>&1 | tee -a ${OUTFILE}"
                ${SUDOMODE} bash ${BASHVERV} ${array}  2>&1 | tee -a ${OUTFILE}
            fi
        done
    fi
    exit 0
fi

#Execute in Remote Host
for H in ${HOST}
do

    if [ "$PING_FLAG" == "true" ] ; then
        ping -W 1 -c 1 ${H} > /dev/null
        if [ "$?" -eq 0 ] ; then
            echo "ping OK ${H} "
        else
            echo "ping NG ${H}"
        fi
    else
        echo ""
        echo "Host : ${H}"
    
        ping -W 1 -c 1 ${H} > /dev/null
        if [ "$?" -ne 0 ] ; then
            echo "[Critical Message] Connection Error Host $H"
            break
        fi
    
        if [ "$LOGIN_FLAG" == "true" ] ; then
            [ "$ECHO" == "on" ] && echo "Execute : ${SSHPASSP} ssh -t ${SSHVERV} ${SSHKEYI} ${USERAT}${H}"
            ${SSHPASSP} ssh -t ${SSHVERV} ${SSHKEYI} ${USERAT}${H}
            [ "$ECHO" == "on" ] && echo  ""
        elif [ "$VI_FLAG" == "true" ] ; then
            [ "$ECHO" == "on" ] && echo "Execute : ${SSHPASSP} ssh -t ${SSHVERV} ${SSHKEYI} ${USERAT}${H} ${SUDOMODE} vi ${REMOTEFILE}"
            ${SSHPASSP} ssh -t ${SSHVERV} ${SSHKEYI} ${USERAT}${H} ${SUDOMODE} vi ${REMOTEFILE}
            [ "$ECHO" == "on" ] && echo  ""
        elif [ "$NANO_FLAG" == "true" ] ; then
            [ "$ECHO" == "on" ] && echo "Execute : ${SSHPASSP} ssh -t ${SSHVERV} ${SSHKEYI} ${USERAT}${H} ${SUDOMODE} nano ${REMOTEFILE}"
            ${SSHPASSP} ssh -t ${SSHVERV} ${SSHKEYI} ${USERAT}${H} ${SUDOMODE} nano ${REMOTEFILE}
            [ "$ECHO" == "on" ] && echo  ""
        elif [ "$SCP_FLAG" == "true" ] ; then
            [ "$ECHO" == "on" ] && echo "Execute : ${SSHPASSP} scp ${SSHKEYI}  ${SCP_LOCAL_FILE} ${USERAT}${H}:${SCP_REMOTE_DIR}"
            echo "${SSHPASSP} scp ${SSHKEYI}  ${SCP_LOCAL_FILE} ${USERAT}${H}:${SCP_REMOTE_DIR}"
            ${SSHPASSP} scp ${SSHKEYI}  ${SCP_LOCAL_FILE} ${USERAT}${H}:${SCP_REMOTE_DIR}
            [ "$ECHO" == "on" ] && echo  ""
        elif [ -z "${FILE}" ] ; then
            #Execute Command
            if [ -z "${OUTFILE}" ] ; then
                [ "$ECHO" == "on" ] && echo "Execute : ${SSHPASSP} ssh ${SSHVERV} ${SSHKEYI} ${USERAT}${H} ${SUDOMODE} \"bash ${BASHVERV} -c \\\"${COMMAND}\\\"\""
                ${SSHPASSP} ssh ${SSHVERV} ${SSHKEYI} ${USERAT}${H} ${SUDOMODE} "bash ${BASHVERV} -c \"${COMMAND}\""
                [ "$ECHO" == "on" ] && echo  ""
            else
                [ "$ECHO" == "on" ] && echo "Execute : ${SSHPASSP} ssh ${SSHVERV} ${SSHKEYI} ${USERAT}${H} ${SUDOMODE} \"bash ${BASHVERV} -c \\\"${COMMAND}\\\"\" 2>&1 | tee -a  ${OUTFILE}"
                echo "$ ssh ${SSHVERV} ${SSHKEYI} ${USERAT}${H} ${SUDOMODE} \"bash ${BASHVERV} -c \\\"${COMMAND}\\\" \" "  >>  ${OUTFILE}
                ${SSHPASSP} ssh ${SSHVERV} ${SSHKEYI} ${USERAT}${H} ${SUDOMODE} "bash ${BASHVERV} -c \"${COMMAND}\"" 2>&1 | tee -a  ${OUTFILE}
                [ "$ECHO" == "on" ] && echo  ""
            fi
        else
            #Create Work Directory
            [ "$ECHO" == "on" ] && echo "Execute : ${SSHPASSP} ssh ${SSHVERV} ${SSHKEYI} -q ${USERAT}${H} \"[ ! -d ${REMOTEWORK} ] && mkdir -p ${REMOTEWORK}\""
            ${SSHPASSP} ssh ${SSHVERV} ${SSHKEYI} -q ${USERAT}${H} "[ ! -d ${REMOTEWORK} ] && mkdir -p ${REMOTEWORK}"
            [ "$ECHO" == "on" ] && echo  ""
    
            #SCP
            for i in ${FILE_UNIQ}
            do
                [ "$ECHO" == "on" ] && echo "Execute : ${SSHPASSP} scp ${SSHKEYI} ${SSHVERV} $i ${USERAT}${H}:${REMOTEWORK}"
                ${SSHPASSP} scp ${SSHKEYI} ${SSHVERV} $i ${USERAT}${H}:${REMOTEWORK}
                [ "$ECHO" == "on" ] && echo  ""
            done
    
            #Execute
            for array in "${arrays[@]}"
            do
                if [ -z "${OUTFILE}" ] ; then
                    [ "$ECHO" == "on" ] && echo "Execute : ${SSHPASSP} ssh ${SSHVERV} ${SSHKEYI} ${USERAT}${H} ${SUDOMODE} bash ${BASHVERV} \"${REMOTEWORK}/${array}\" "
                    ${SSHPASSP} ssh ${SSHVERV} ${SSHKEYI} ${USERAT}${H} ${SUDOMODE} bash ${BASHVERV} "${REMOTEWORK}/${array}"
                    [ "$ECHO" == "on" ] && echo  ""
                else
                    [ "$ECHO" == "on" ] && echo "Execute : ${SSHPASSP} ssh ${SSHVERV} ${SSHKEYI} ${USERAT}${H} ${SUDOMODE} bash ${BASHVERV} \"${REMOTEWORK}/${array}\"  2>&1 | tee -a ${OUTFILE}"
                    echo "$ ssh ${SSHVERV} ${SSHKEYI} ${USERAT}${H} ${SUDOMODE} bash ${BASHVERV}  \"${REMOTEWORK}/${array}\""  >>  ${OUTFILE}
                    ${SSHPASSP} ssh ${SSHVERV} ${SSHKEYI} ${USERAT}${H} ${SUDOMODE} bash ${BASHVERV} "${REMOTEWORK}/${array}"  2>&1 | tee -a ${OUTFILE}
                    [ "$ECHO" == "on" ] && echo  ""
                fi
            done
    
            #Delete file
            for i in ${FILE_UNIQ}
            do
                [ "$ECHO" == "on" ] && echo "Execute : ${SSHPASSP} ssh ${SSHKEYI} ${USERAT}${H}  rm -f ${REMOTEWORK}/$i "
                #${SSHPASSP} ssh ${SSHKEYI} ${USERAT}${H} ls -l ${REMOTEWORK}/$i
                ${SSHPASSP} ssh ${SSHKEYI} ${USERAT}${H}  rm -f ${REMOTEWORK}/$i
            done
        fi
    fi
done
