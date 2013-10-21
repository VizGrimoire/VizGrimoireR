#! /bin/sh

cont=8000
sleeper=5
while [ $cont -lt 1450000 ]; 
do   
  prev=$cont
  cont=`echo $cont+250|bc`
  condition=-1
  while [ $condition -ne 0 ]
  do
    wget http://download.gmane.org/gmane.linux.kernel/$prev/$cont 2>>log.txt
    condition=$?
  done
  sleeper=`echo $RANDOM % 10 + 1 | bc`
  sleep $sleeper
  echo $cont
done
