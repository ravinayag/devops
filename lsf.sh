#!/bin/bash

###edit the following
cservice1=mysql
cservice2=apache2
cservice3=ufw1
#cservice3=www-data

pservice=lsf
email=r@localhost

### Non Editable  Variables, until you know what you doing.
host=`hostname -f`
z=0
dat=$(date)

is_running1=`ps aux | grep -v grep| grep $cservice1| wc -l | awk '{print $1}'`
is_running2=`ps aux | grep -v grep| grep $cservice2| wc -l | awk '{print $1}'`
is_running3=`ps aux | grep -v grep| grep $cservice3| wc -l | awk '{print $1}'`

#if [ $is_running1 != '0' || $is_running2 != '0' || $is_running3 != '0' ] ;
#if [ $is_running1 != '0' ] || [ $is_running2 != '0' ] || [ $is_running3 != '0' ] ;
if [ $is_running1 != $z ] && [ $is_running2 != $z ] && [ $is_running3 != $z ] ;

#if (( $(ps -ef | grep -v grep | grep $cservice1 | wc -l) > 0 ) || ( $(ps -ef | grep -v grep | grep $cservice2 | wc -l) > 0 ) || ( $(ps -ef | grep -v grep | grep $cservice3 | wc -l) > 0 ));
then
echo " Date&Time : $dat @@~~~~@@ " >>  /home/ravi/ra/rlog.log
echo "$cservice1=$is_running1, $cservice2=$is_running2, $cservice3=$is_running3 is  running" >> /home/ravi/ra/rlog.log
echo "Since all service running, no LSF service restart or email notfication required" >> /home/ravi/ra/rlog.log
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >>/home/ravi/ra/rlog.log

echo " Date&Time : $dat @@~~~~@@ Before Restart " >>  /home/ravi/ra/rlog.log
echo "One of 3 services is not running hence restarting Parent lsf service"
echo "LSF Child services $cservice1, $cservice2, $cservice3 is not  running" >> /home/ravi/ra/rlog.log


/etc/init.d/$pservice restart
echo " " >> /home/ravi/ra/rlog.log
echo " Date&Time : $dat @@~~~~@@ After Restart "  >>  /home/ravi/ra/rlog.log

#if (( $(ps -ef | grep -v grep | grep $cservice1 | wc -l) > 0 ))
if [ $is_running1 != $z ] && [ $is_running2 != $z ] && [ $is_running3 != $z ] ;
then
subject="$pservice at $host has been restarted"
echo "$pservice at $host wasn't running and has been restarted" | mail -s "$subject" $email


else
subject="$pservice at $host is failed to restart"
echo "$pservice at $host is not running  and cannot be started!!!" | mail -s "$subject" $email
fi
echo "mail sent " >> /home/ravi/ra/rlog.log
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >>/home/ravi/ra/rlog.log
fi
