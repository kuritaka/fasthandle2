#!/bin/bash
#=============================================================
VERSION="2.0.0 beta"

usage_exit() {
cat <<HELP
Usage: fh  [options] 

Options:
    -h, --help              show this help message and exit
    --version               show program's version number and exit
    -v, --verbose           verbose mode
    -H HOST1[,HOST2], --hosts=HOST1[,HOST2]
    -H FILE
                            comma-separated list of hosts to operate on
    -o [OUTPUTFILE]         Write output to <file> instead of stdout
    -c COMMAND, --command=COMMAND
                            Execute COMMAND
    -s SHELLSCRIPT          Execute ShellScript

  Connection Options:
    control as whom and how to connect to hosts

    -u USER, --user=USER    username to use when connecting to remote hosts
    -i PRIVATEKEY           SSH private key file.
    -p PORT, --port=PORT    Port to connect to on the remote host.


Example of Execute in Local Host:
  fh -c uname -n
  fh -s script/test1.sh
  fh -s script/test1.sh:arg1,arg2 script/test2.sh:arg1,arg2
  fh -o outputfile -c uname -n
  fh -o -c uname -n   # default outputfile

Example f Execute in Remote Host:
  fh -H host1 -c uname -n
  fh -H host1,host2 -c uname -n
  fh -H host1,host2 -s script/test1.sh
  fh -H hostlist -s script/test1.sh
HELP
}
#=============================================================

PROGNAME=$(basename $0)
SCRIPTDIR=$(cd $(dirname $0); pwd)

#Default Path
LOCALHOME="$HOME/fasthandle"
LOCALWORK="$LOCALHOME/work"
LOCALLOG="$LOCALHOME/log"

#REMOTEHOME="$HOME/fasthandle"
#REMOTEWORK="$REMOTEHOME/work"
#REMOTELOG="$REMOTEHOME/log"

#REMOTEHOME="$HOME/fasthandle"
REMOTEWORK="/tmp"
#REMOTELOG="$REMOTEHOME/log"


if [ -z "${SCRIPTDIR}/fh.conf" ] ; then
    source ${SCRIPTDIR}/fh.conf
fi


#===============================================
[ ! -d ${LOCALHOME} ] && mkdir -p ${LOCALHOME}
[ ! -d ${LOCALWORK} ] && mkdir -p ${LOCALWORK}
[ ! -d ${LOCALLOG} ] && mkdir -p ${LOCALLOG}

#Function

host_parce(){
    #Check File
    if [ -f "$ARGHOST" ]; then
        HOST=$(grep -v "^#" $ARGHOST | awk '{ print $1}')
    else
        H=`echo $ARGHOST | tr "," " "`
        HOST=`echo $H`
    fi

    echo "HOST : $(echo $HOST)"
}

out_parce(){
    OUTFILE=$(echo $OUT)

    if [ -z "$OUTFILE" ] ; then
        OUTFILE="${LOCALLOG}/$(date +%Y%m%d_%H%M%S).log"
    else
        OUTFILE="${LOCALLOG}/${OUTFILE}"
    fi
    #OUTTEE=" 2>&1 | tee -a $OUTFILE"

    echo "LOG : $OUTFILE"
}

command_parce(){
    #echo "COMMAND before = $COMMAND"

    COMMAND=`echo $COMMAND`

    echo "COMMAND = $COMMAND"
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
                    arrays+=("$F $args")
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
                    echo "for args : $args"
                    SHELL=$(basename $F)
                    arrays+=("$SHELL $args")
                done

                #ENDA=$(echo $ENDA $A)
                #echo $ENDA
            fi
        fi
    done

}



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
        -u | --user*)
            if [[ "$1" =~ "--user" ]] ; then
                SSHUSER=$(echo $1 | awk -F= '{ print $2"@" }')
            else
                SSHUSER="$2@"
                shift
            fi
            ;;
        -i )
            SSHKEY="-i $2"
            shift
            ;;
        -p | --port*)
            if [[ "$1" =~ "--port" ]] ; then
                SSHPORT=$(echo $1 | awk -F= '{ print $2 }')
            else
                SSHPORT="$2"
                shift
            fi
            ;;
        -H | --hosts*)
            if [[ "$1" =~ "--hosts" ]] ; then
                ARGHOST=$(echo $1 | awk -F= '{ print $2 }')
            else
                ARGHOST="$2"
            fi
            host_parce
            shift
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
            if [[ "$1" =~ "--command" ]] ; then
                COMMAND=$(echo $* | awk -F= '{ {for(i=2;i<NF;i++)printf("%s ",$i) }print($NF) }')
                command_parce
            else
                shift
                COMMAND="$*"
                command_parce
            fi
            break
            ;;
        -s | --shellscript )
            if [[ "$1" =~ "--command" ]] ; then
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

#Check Only Parameter
#echo $SSHUSER
#exit


echo ""
if [ "$VERV_FLAG" == "true" ] ; then
    SSHVERV="-v"
    BASHVERV="-x"
else
    SSHVERV="-q"
    BASHVERV=""
fi

#Execute in Local Host
if [ -z "${HOST}" ]; then
    if [ -z "${FILE}" ] ; then
        if [ -z "${OUTFILE}" ] ; then
            bash ${BASHVERV} -c "${COMMAND}"
        else
            bash ${BASHVERV} -c "${COMMAND}" 2>&1 | tee -a "${OUTFILE}"
        fi
    else
        #Execute
        for array in "${arrays[@]}"
        do
            if [ -z "${OUTFILE}" ] ; then
                bash ${BASHVERV} -c "${array}"
            else
                bash ${BASHVERV} -c "${array}"  2>&1 | tee -a ${OUTFILE}
            fi
        done
    fi
    exit 0
fi

#Execute in Remote Host
for H in ${HOST}
do
    echo ""
    echo "Host : ${H}"

    ping -c 1 ${H} > /dev/null
    if [ "$?" -ne 0 ] ; then
        echo "[Critical Message] Connection Error Host $H"
        break
    fi


    if [ -z "${FILE}" ] ; then
        if [ -z "${OUTFILE}" ] ; then
            ssh -n ${SSHVERV} ${SSHKEY} ${SSHUSER}${H} ${COMMAND}
        else
            ssh -n ${SSHVERV} ${SSHKEY} ${SSHUSER}${H} "${COMMAND}" 2>&1 | tee -a  ${OUTFILE}
        fi
    else
        #Create Work Directory
        ssh -n ${SSHVERV} ${SSHKEY} -q ${SSHUSER}${H} "[ ! -d ${REMOTEWORK} ] && mkdir -p ${REMOTEWORK}"

        #SCP
        for i in ${FILE_UNIQ}
        do
            scp ${SSHKEY} ${SSHVERV} $i ${SSHUSER}${H}:${REMOTEWORK}
        done

        #Execute
        for array in "${arrays[@]}"
        do
            if [ -z "${OUTFILE}" ] ; then
                ssh -n ${SSHVERV} ${SSHKEY} ${SSHUSER}${H} bash ${BASHVERV} "${REMOTEWORK}/${array}"
            else
                ssh -n ${SSHVERV} ${SSHKEY} ${SSHUSER}${H} bash ${BASHVERV} "${REMOTEWORK}/${array}"  2>&1 | tee -a ${OUTFILE}
            fi
        done
    fi

done
