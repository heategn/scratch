#!/bin/bash

function countdown(){
	SECONDS=$(($1 * 60))
   	date1=$((`date +%s` + $SECONDS)); 
   	while [ "$date1" -ge `date +%s` ]; do 
     		sleep 1
   	done

   	kdialog --msgbox "$1 minutes have elapsed."
}

if [[ -z $(echo "$1" | grep -o '^[0-9]*$') ]]; then
	echo 'Please enter an integer.'
	exit 1
fi

if [[ -z $1 ]]; then
	echo 'Please enter the number of minutes to wait.'
	exit 1
fi

if [[ $1 -lt 1 ]]; then
	echo 'Please enter at least 1 minute.'
	exit 1
fi


countdown $1

exit 0;
