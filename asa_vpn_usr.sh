#!/bin/bash

script_directory="/etc/zabbix/ext_scripts/"

if [[ $3 == "discover" ]]
then
act_usr=`snmpwalk -v 2c -c $2 $1 1.3.6.1.4.1.9.9.392.1.3.21.1.10 | awk -F "." '{for(i=11;i<(NF-3);++i) printf "%c", $i; printf "\n"}' | uniq`$'\n'

if [ ! -f "$script_directory/asa_usr_lst" ]; then
 printf '%s' "$act_usr" | while IFC= read -r name
  do
   echo -n "$name|1|" >> "$script_directory/asa_usr_lst"
  done
else
 IFS='| ' read -r -a usr_all <<< `cat $script_directory/asa_usr_lst`
 for (( c=0; c<=${#usr_all[@]}; c++ ))
  do
   if [ "${usr_all[$c]}" == "1" ];
    then usr_all[$c]="0"
   fi
  done
 printf '%s\n' "$act_usr" | ( while IFC= read -r  name_act 
 do
  count=0;
   for (( c=0; c<${#usr_all[@]}; c++ ))
    do
     if [ "${usr_all[$c]}" != "0" ] && [ "$name_act" != "" ]; then
      if [ "${usr_all[$c]}" == "$name_act" ]; 
       then 
        usr_all[(($c+1))]="1";
	count=0;
	break;
       else
        ((count++));
      fi
     fi
    done
  if [ "$count" != "0" ]; then
   echo $name_act
   usr_all+=($name_act);
   usr_all+=('1');
  fi 
 done
IFS="|$IFS";
printf '%s' "${usr_all[*]}" > "$script_directory/asa_usr_lst";
IFS="{IFS:1}");
echo "|" >> "$script_directory/asa_usr_lst"
fi


 IFS='| ' read -r -a usr_dvr <<< `cat $script_directory/asa_usr_lst`;
 json="{\"data\":["; 
 for (( c=0; c<${#usr_dvr[@]}; c++ ))
  do
   if ! [[ "${usr_dvr[$c]}" =~ ^[0-1,]+$ ]];
    then 
     json="$json{\"{#USERNAME}\":\"";
     json1="$(echo -n ${usr_dvr[$c]} | sed 's,\\,\\\\,g')"
     json="$json$json1"
     if [[ "$c" == "$((${#usr_dvr[@]}-2))" ]]
     then json="$json\"}";
     else json="$json\"},";
     fi
   fi
  done
 json="$json]}"
 echo "$json";
fi


if [[ $3 == "check" ]];
then
 if [[ -n $4 ]];
 then
  IFS='| ' read -r -a usr_chk <<< `cat $script_directory/asa_usr_lst`;
  for (( c=0; c<${#usr_chk[@]}; c++ ))
  do
   if [[ "${usr_chk[$c]}" == "$4" ]];
    then
     echo "${usr_chk[(($c+1))]}";
     break;
   fi
  done
 else
  echo "name is not defined";
 fi
fi
