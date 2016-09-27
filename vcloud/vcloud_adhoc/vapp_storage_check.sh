#!/bin/bash

AGENT='Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3'
HEADER='Accept:application/*+xml;version=5.6'

read -p "API URL (https://something.example.com/api): " APIURL
read -p "Username: " USER
read -s -p "Password: " PASSWD

echo "connecting to $APIURL..."
VORGID=`curl -c cookie -s -A "$AGENT" -i -k -H "$HEADER" -u "$USER:$PASSWD" -X POST "$APIURL/sessions"|grep "application/vnd.vmware.vcloud.org+xml"|head -n1|awk -F 'api/org/' '{print $2}'|awk -F "\"" '{print $1}'`
SESSION=`curl -c cookie -s -A "$AGENT" -i -k -H "$HEADER" -u "$USER:$PASSWD" -X POST "$APIURL/sessions"|grep 'x-vcloud-authorization:'|awk '{gsub(/\r/,""); print $2}'`




echo "get VDCs..."
VDCS=`curl -s -c cookie -k -A "$AGENT" -H "$HEADER" -u "$USER:$PASSWD" -H "x-vcloud-authorization: $SESSION" -X GET "$APIURL/org/$VORGID"|while read LINE;do if [[ $LINE == *"api/vdc"* ]] ; then echo $LINE|awk -F 'name="' '{print $2}'|awk -F '"' '{print $1}';echo $LINE|awk -F 'api/vdc/' '{print $2}'|awk -F "\"" '{print $1}';fi;done`

echo "get vApps..."
echo "$VDCS"|while read VDC;
        do read VDCID;
#                echo -e "\n\n $VDC";
#echo "<VDC = $VDC>"
                VAPPS=`curl -s -c cookie -k -A "$AGENT" -H "$HEADER" -u "$USER:$PASSWD" -H "x-vcloud-authorization: $SESSION" -X GET "$APIURL/vdc/$VDCID"|while read LINE;do if [[ $LINE == *"api/vApp/"* ]] ; then echo $LINE|awk -F 'name="' '{print $2}'|awk -F '"' '{print $1}';echo $LINE|awk -F 'api/vApp/' '{print $2}'|awk -F "\"" '{print $1}';fi;done`;
                echo "$VAPPS"|while read VAPP;
                  do
                  if [[ $VAPP == *"vapp-"* ]] ; then



NETWSTRING=`curl -s -c cookie -k -A "$AGENT" -H "$HEADER" -u "$USER:$PASSWD" -H "x-vcloud-authorization: $SESSION" -X GET "$APIURL/vApp/$VAPP"|egrep 'StorageProfile|VirtualSystemIdentifier|rasd:ElementName|rasd:HostResource'`

echo "$NETWSTRING"|tr ">" "\n"|while read LINE;do
if [[ $LINE == *"StorageProfile href"* ]] ;then
     TEXT=`echo -n "$LINE "|awk -F '"' '{print $4}'`
     StorageProfile=`echo -n "$TEXT"`
echo $StorageProfile > /tmp/strg.tmp
fi
done

VMname=" "
echo "$NETWSTRING"|tr ">" "\n"|while read LINE;do
   if [[ $LINE == *"Hard disk "* ]] ; then
    echo $LINE|while read DISK;do
       TEXT=`echo -n "$LINE "|awk -F '<' '{print $1}'`
       echo -n "$VDC;$VMname;$TEXT;$StorageProfile"
    done
   elif [[ $LINE == *"vcloud:capacity"* ]] ;then
     echo -n ";" 
     echo "$LINE"|awk -F '"' '{print $2";"$6}'
   elif [[ $LINE == *"VirtualSystemIdentifier"* ]] ;then
     TEXT=`echo -n "$LINE "|awk -F '<' '{print $1}'`
     VMname=`echo -n "$TEXT"`
     StorageProfile=`cat /tmp/strg.tmp`
   fi
done


fi
done
done
