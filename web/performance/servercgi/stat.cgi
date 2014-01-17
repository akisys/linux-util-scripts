#!/bin/bash

echo Content-type: text/plain
echo ""

case "$REMOTE_ADDR" in
  "192.168."*) ;;
  "127.0."*);;
  *) exit 1;;
esac

if [[ -n "${QUERY_STRING//[0-9A-Za-z]/}" ]];
then
  exit 1;
fi;

wwwuser="www-data"
mysqluser="mysql"

f_ap2_info(){
  raw_info=$(ps -U $wwwuser -u $wwwuser -o comm,rsz,vsz chmS)
  mem_proc=$(echo "$raw_info"|awk '/apache2/{cnt+=1;rsz+=$2;vsz+=$3;}END{print rsz","vsz","cnt}')
  threads=$(echo "$raw_info"|awk '/apache2/{$0="";f=1}{p=$0}f'|sed '/^$/d'|wc -l)
  echo -en "$mem_proc,$threads"
}
f_mysql_info(){
  raw_info=$(ps -U $mysqluser -u $mysqluser -o comm,rsz,vsz chmS)
  mem_proc=$(echo "$raw_info"|awk '/mysqld/{cnt+=1;rsz+=$2;vsz+=$3;}END{print rsz","vsz","cnt}')
  threads=$(echo "$raw_info"|awk '/mysqld/{$0="";f=1}{p=$0}f'|sed '/^$/d'|wc -l)
  echo -en "$mem_proc,$threads"
}
f_load(){
  uptime=$(uptime|cut -d\  -f10-|cut -d: -f2|sed -e 's/\s*//g')
  echo -en "$uptime"
}

case $QUERY_STRING in
  load) f_load;;
   ap2) f_ap2_info;;
    ms) f_mysql_info;;
   all) f_load; echo -en ",";
        f_ap2_info; echo -en ",";
        f_mysql_info;;
esac;
exit 0;

