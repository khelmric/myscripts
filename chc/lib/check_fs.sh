#!/bin/bash
STATUS="OK"

COL_OK='\E[32;40m'
COL_NOK='\E[31;40m'
COL_DEF='\E[37;40m'
COL_WARN='\E[33;40m'

    echo -en $COL_NOK
    while read line;do
        SIZE=`echo $line|awk '{print $5}'|sed 's/\(.*\)./\1/'`
        if [[ $SIZE -gt 90 ]];then
            if [[ $SIZE -gt 95 ]];then
                echo -en $COL_NOK
                STATUS="NOK"
                echo "Filesystems above 95%:"
            else
                echo -en $COL_WARN
                STATUS="NOK"
                echo "Filesystems above 90%:"
            fi
                line=`echo $line|sed 's/.*\s*Avail\s*.*//'`
                echo -e  "             $line"
                echo   "$line"
        fi
    done < <(df -Ph)
    if [[ $STATUS == OK ]]; then
      echo -en $COL_OK
      echo "All FS are below 90%"
    fi

    echo -en $COL_DEF
