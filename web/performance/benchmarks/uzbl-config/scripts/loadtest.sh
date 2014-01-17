#!/bin/bash

sessionfile="uzbltest_session_$UZBLTEST_URLHASH.sh"
resourcefile="uzbltest_resources_$UZBLTEST_URLHASH.lst"
resultfile="uzbltest_results_$UZBLTEST_URLHASH.txt"

if [[ -e $sessionfile ]]
then
  . $sessionfile
else
  echo -e "#!/bin/bash\n\n" > $sessionfile;
  chmod +x $sessionfile;
fi

datestr="+%s.%N"


f_start(){
  echo "START=$(date $datestr)" >> $sessionfile;
  rm -f $resourcefile;
}

f_stop(){
  url=$1
  END=$(date $datestr)
  timing=$(echo "$END - $START"|bc)
  while read line; do
    filename=$(basename $line|cut -d? -f1);
    case $filename in
      *jpeg|*jpg|*png|*gif)
        img_count=$(($img_count + 1));
        ;;
      *js)
        script_count=$(($script_count + 1));
        ;;
      *css)
        css_count=$(($css_count + 1));
        ;;
    esac
    req_count=$(($req_count + 1));
  done < $resourcefile;
  rm -f $sessionfile;
  echo -e "$(date +%Y/%m/%d\ %H:%M:%S) url:$url; time:0$timing; requests:$req_count; images:$img_count; scripts:$script_count; css:$css_count;" >> $resultfile;
  kill -TERM $UZBL_PID;
  echo "ended browser"
}
f_error(){
  echo ${@}, requested;
}
f_request(){
  echo ${@} >> $resourcefile;
}

case $1 in
  start) 
    f_start;
    ;;
  stop|test)  
    f_stop ${@:2};
    ;;
  error)  
    f_error ${@:2};
    ;;
  request)  
    f_request ${@:2};
    ;;
  *)
    #echo ${*};
    ;;
esac
exit 0;
