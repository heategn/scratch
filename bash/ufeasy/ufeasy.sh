#!/bin/bash

declare -a RULES
declare -a DEACTIVATED
declare RULE=""
declare number
declare DEBUG=false
RULES_FILE="$PWD/ufrules"
idx=1
idx=2

if [ ${1:-0} == "-d" ]; then
  DEBUG=true
fi

function synchronize() {
  start=0
  :>$RULES_FILE
  sudo ufw status | while read line; do
    read -ra rule <<< "$line"
    
    if [[ -z $line ]]; then
      continue
    fi

    if [[ $start -eq 0 ]]; then
      #Begin parsing
      if [[ ${rule[0]} == '--' ]]; then
        start=1
      fi
      continue
    fi

    len=${#rule[@]}
    if [[ $len -eq 0 ]]; then
      continue
    fi

    let len="$len - 1"

    possible_actions='ALLOW OUT|ALLOW|DENY OUT|DENY'
    ip_regex='[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
    FROM=$(echo $line | grep -oP "(?<=ALLOW|DENY).*$")
    ACTION=$(echo $line | grep -oP "$possible_actions")
    TO=$(echo $line | grep -oP '^.*(?='"$possible_actions"')')
    FROM=$(echo $FROM | sed 's/\s*OUT\s*//')

    #Get the port
    port=$(echo $TO | grep -oP '([\s]+[0-9]+$)|(^[0-9]+$)')
    
    if [[ -n $port ]]; then
      port="port $port"
    fi

    #Get the address
    address=$(echo $TO | grep -oP "^$ip_regex")

    if [[ -z $address ]]; then
      #Must be an alias
      if [[ -z $port ]]; then
        address=$(echo $TO | grep -oP "^.*$")
        address="app $address"
      else
        address=" any" 
      fi
    fi

    #To lowercase
    ACTION=$(echo $ACTION | tr '[:upper:]' '[:lower:]')

    ufw_rule="$ACTION from $FROM to $address $port"
   echo $ufw_rule
    echo $ufw_rule >> $RULES_FILE
    for d in ${DEACTIVATED[@]}; do
      echo "-- $d" >> $RULES_FILE
    done

    #  printaction "Rules file synchronized"

  done

}

# synchronize
# exit

function mainmenu() {

	readrules
	
  if [ -n "$ACTION" ]; then
    printaction "$ACTION"
    ACTION=''
  fi

	echo "1: Add rule"
	echo "2: Delete rule"
	echo "3: Activate rule"
	echo "4: De-activate rule"
  echo "5: Synchronize with UFW"
	echo "6: Quit"
	read -p "Choose option: " answer
	
	if [ "$answer" == "1" ]; then
		addrule
		echo ''
	fi

	if [ "$answer" == "2" ]; then
		deleterule
		echo ''
	fi
	
	if [ "$answer" == "3" ]; then
		activaterule
		echo ''
	fi
	
	if [ "$answer" == "4" ]; then
		deactivaterule
		echo ''
	fi
	
  if [ "$answer" == "5" ]; then
    synchronize
    echo ''
  fi

	if [ "$answer" == "6" ]; then
		echo "Quitting"
		exit 0
	fi
	
	mainmenu
	
}

function synchronize() {
  sudo ufw status | while read line; do
    declare -a rule
    IFS=" "
    rule=("line")
    echo $rule
  done
}

function addrule() {
  readrules
  read -p "Enter the rule here: " rule
  if [ "$rule" != -z ]; then
    echo "--$rule" >>${RULES_FILE}
    ACTION='Rule added, but not yet activated.'
  else
    echo "Rule is blank."
  fi
}

function printred() {
  if [[ -z $1 ]]; then
    echo -e "\e[31mThere was a problem\e[0m"
  else
    echo -e "\e[31m$1\e[0m"
  fi
}

function printgreen() {
  echo -e "\e[32m$1\e[0m"
}

function printaction(){
  echo
  echo -e "\e[44;97m$1\e[0m"
  echo
}

function deleterule() {
  readrules
  read -p "Enter rule # to delete (0 to exit): " number
  if [ $number != 0 ]; then
    if [ ${DEACTIVATED[$number]:=0} == 0 ]; then
      printred "Rule does not exist"
      return 1
    fi
    sed -i /"${DEACTIVATED[$number]}"/d ${RULES_FILE}
    unset DEACTIVATED[$number]
    ACTION='Rule deleted'
  fi
}

function getRule() {

  if [ $1 == 'activate' ]; then
    read -p "Enter rule # to activate: " number
  else
    read -p "Enter rule # to de-activate: " number
  fi

  if [ "$number" != 0 ]; then
    if [ $1 == "deactivate" ]; then
      RULE="${RULES[$number]}"
    else
      r="${DEACTIVATED[$number]}"
      RULE="${r:2}"
    fi
  else
    return 0
  fi
  return 1

}

function runufw() {
  
  if [ $DEBUG == true ]; then
    return 0
  fi
  
  if [ $1 == "add" ]; then
    sudo ufw insert 1 $RULE
  else
    echo "---$RULE---"
    sudo ufw delete $RULE
  fi
    
}

function activaterule() {
  readrules
  getRule "activate" 

  if [ $? != 0 ]; then
    runufw "add"
    if [ $? != 0 ]; then
      printred
      return 0
    fi
    escaped=${RULE/"/"/"\/"}
    sed  -i 's/--'"${escaped}"'/'"${escaped}"'/' ${RULES_FILE}
    unset DEACTIVATED[$number]
    ACTION='Rule activated'
  fi
}

function deactivaterule() {

  readrules
  getRule "deactivate"
  
  if [ $? != 0 ]; then
    runufw "delete"
    if [ $? != 0 ]; then
      printred
      return 0
    fi
    escaped=${RULE/"/"/"\/"}
    sed -i 's/'"${escaped}"'/--&/' ${RULES_FILE}
    unset RULES[$number]
    ACTION='Rule deactivated'
  fi

}

function readrules() {
    
    let idx=1
    let idx2=1
    echo ""
    
    printgreen "--------------------------"
    printgreen "-------ACTIVATED----------"
    printgreen "--------------------------"
    while read line; do
      if [ ${line:0:2} != '--' ]; then
        printgreen "$idx $line"
        RULES[$idx]=$line
        let idx=$idx+1
      fi
    done < ${RULES_FILE}
    echo ''
    printred "--------------------------"
    printred "-------DEACTIVATED--------"
    printred "--------------------------"
    while read line; do
      if [ ${line:0:2} == '--' ]; then
        printred "$idx2 ${line:2}"
        DEACTIVATED[$idx2]=$line
        let idx2=$idx2+1
      fi
    done < ${RULES_FILE}
    echo ""

}

if [ ! -f $RULES_FILE ]; then
  printred "$RULES_FILE file is missing!"
  exit 1
fi

mainmenu

exit 0