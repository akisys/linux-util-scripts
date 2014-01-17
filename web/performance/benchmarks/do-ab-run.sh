#!/bin/bash


# bail on any error
set -e
# script bootstrap
if [[ $1 != boot/strap ]]; then
  . $0 boot/strap
  f_main "$@"
  exit 0;
fi

tool_bin="/usr/bin/ab"
basedir=`pwd`"/ab-run"
data_storage="$basedir/"`date +%Y%m%d_%H-%M-%S`
server_stat_url="/cgi-bin/stat.cgi"
## global vars for setup blocks
concurrent=5
requests=250
gnuplot_base="gpdata"
gpscript_base="gpscript"
gpout_base="gpplot"
log_base="log"
report_base="report"
info_base="serverinfo"
runcount=5
intersleep=5 #seconds

f_main(){ #{{{1
  choice=$1 || ""
  case $choice in
       basic-test) f_basic_test_setup; f_run_test ${@:2};;
    extended-test) f_extended_test_setup; f_run_test ${@:2};;
        burn-test) f_burn_test_setup; f_run_test ${@:2};;
                *) echo -e "Menu option not recognized\n" >&2; f_help; exit 1;;
  esac
  exit 0;
}

f_help(){ #{{{1
  cat <<EOM
USAGE: $0 OPTION PARAMETERS

Available options:
basic-test URL
extended-test URL
burn-test URL

EOM
}

f_gp_test_base(){ #{{{1
  outfile="$1"
  params="$2"
  echo """
# output as pdf document
set terminal pdf color enhanced font 'verdana,11' size 21cm,29.7cm
# iso a4 ratio
set size 1,1.4142
# save file to '$outfile'
set output '$outfile.pdf'
set multiplot
# graph title
set title 'ab $params' offset 0,-0.9
# xy-axis grid
set grid y
set grid x
# x-axis label
set xlabel 'request' offset 0,0.9
set xtics autofreq font 'verdana,8'
# y-axis label
set ylabel 'response time (in ms)' offset 0.5,0
set ytics font 'verdana,8'
# move legend box
set key outside top

set size 1,0.25
set origin 0,0

  """
}

f_gp_info_output(){ #{{{1
  info_file="$1"
  count="$2"
  echo -en "\n\n\n"
  echo -en "set datafile separator ','\nset nokey\nset ylabel 'load (in %)'\nset xlabel 'runs'\n";
  echo -en "set xrange [0:$(($count+1))]\nset xtics autofreq\nset ytics autofreq\n"
  for col in $(seq 1 11); do
    case $col in
      1) 
        echo -en "set size 0.33,0.133\nset origin 0,0.25\nset title 'load1'\n";
        echo -en "plot '$info_file' using (\$$col*100) smooth sbezier title 'load1'\n\n";
        ;;
      2) 
        echo -en "set size 0.33,0.133\nset origin 0.33,0.25\nset title 'load5'\n";
        echo -en "plot '$info_file' using (\$$col*100) smooth sbezier title 'load5'\n\n";
        ;;
      3) 
        echo -en "set size 0.33,0.133\nset origin 0.66,0.25\nset title 'load15'\n";
        echo -en "plot '$info_file' using (\$$col*100) smooth sbezier title 'load15'\n\n";
        ;;
      4)
        echo -en "set ytics 5\n"
        echo -en "set size 0.5,0.17\nset origin 0,0.37\nset title 'apache real memory'\n";
        echo -en "set ylabel 'rmem (in MB)'\n";
        echo -en "plot '$info_file' using (\$$col/1024) with lines title 'mem'\n\n";
        ;;
      5) 
        echo -en "set ytics 5\n"
        echo -en "set size 0.5,0.17\nset origin 0.5,0.37\nset title 'apache virtual memory'\n";
        echo -en "set ylabel 'vmem (in MB)'\n";
        echo -en "plot '$info_file' using (\$$col/1024) with lines title 'mem'\n\n";
        ;;
      6) 
        echo -en "set ytics 1\n"
        echo -en "set size 0.5,0.16\nset origin 0,0.53\nset title 'number of apache processes'\n";
        echo -en "set ylabel 'processes'\n";
        echo -en "plot '$info_file' using $col with lines title 'processes'\n\n";
        ;;
      7) 
        echo -en "set ytics 1\n"
        echo -en "set size 0.5,0.16\nset origin 0.5,0.53\nset title 'number of apache threads'\n";
        echo -en "set ylabel 'threads'\n";
        echo -en "plot '$info_file' using $col with lines title 'threads'\n\n";
        ;;
      8) 
        echo -en "set ytics 5\n"
        echo -en "set size 0.5,0.17\nset origin 0,0.68\nset title 'mysql real memory'\n";
        echo -en "set ylabel 'rmem (in MB)'\n";
        echo -en "plot '$info_file' using (\$$col/1024) with lines title 'mem'\n\n";
        ;;
      9) 
        echo -en "set ytics 5\n"
        echo -en "set size 0.5,0.17\nset origin 0.5,0.68\nset title 'mysql virtual memory'\n";
        echo -en "set ylabel 'vmem (in MB)'\n";
        echo -en "plot '$info_file' using (\$$col/1024) with lines title 'mem'\n\n";
        ;;
      10) 
        echo -en "set ytics 1\n"
        echo -en "set size 0.5,0.16\nset origin 0,0.84\nset title 'number of mysql processes'\n";
        echo -en "set ylabel 'processes'\n";
        echo -en "plot '$info_file' using $col with lines title 'processes'\n\n";
        ;;
      11) 
        echo -en "set ytics 1\n"
        echo -en "set size 0.5,0.16\nset origin 0.5,0.84\nset title 'number of mysql threads'\n";
        echo -en "set ylabel 'threads'\n";
        echo -en "plot '$info_file' using $col with lines title 'threads'\n\n";
        ;;
    esac
  done
  echo "unset multiplot"
}

f_request_server_info(){ #{{{1
  # request server info, all
  _info=$(wget -qO- "$server_stat_url?all")
  echo -e -n "$_info\n"
}

f_basic_test_setup(){ #{{{1
  concurrent=5
  requests=250
  gnuplot_base="basic_$gnuplot_base"
  gpscript_base="basic_$gpscript_base"
  gpout_base="basic_$gpout_base"
  log_base="basic_$log_base"
  runcount=10
}

f_extended_test_setup(){ #{{{1
  concurrent=5
  requests=500
  gnuplot_base="ext_$gnuplot_base"
  gpscript_base="ext_$gpscript_base"
  gpout_base="ext_$gpout_base"
  log_base="ext_$log_base"
  runcount=10
}

f_burn_test_setup(){ #{{{1
  concurrent=8
  requests=1500
  gnuplot_base="burn_$gnuplot_base"
  gpscript_base="burn_$gpscript_base"
  gpout_base="burn_$gpout_base"
  log_base="burn_$log_base"
  runcount=30
}

f_run_test(){ #{{{1
  if [[ -z "$1" ]]; then
    echo -e "Missing URL!";
    exit 1;
  fi
  server_stat_url=$(echo "$1"|cut -d/ -f1-3)$server_stat_url;
  # setup data storage directories
  echo -e "Data directory is: $data_storage"
  mkdir -p "$data_storage"
  # setup test variables
  url=$1
  urlhash=`echo $url|md5sum|cut -d\  -f1`
  report_file="$report_base"_"$urlhash.txt"
  report="$data_storage/$report_file"
  info_file="$info_base"_"$urlhash.txt"
  info="$data_storage/$info_file"
  gp_test_input="$data_storage/$gpscript_base"_"$urlhash.p"
  gp_test_output="$gpout_base"_"$urlhash"
  # request server info before test runs
  f_request_server_info > $info;
  ####### START OF TEST RUNS ##########
  for run in $(seq 1 $runcount);
  do
    #request server info
    f_request_server_info >> $info;
    gnuplot_file="$gnuplot_base"_"$run"_"$urlhash.dat"
    gp="$data_storage/$gnuplot_file"
    log_file="$log_base"_"$run"_"$urlhash.log"
    log="$data_storage/$log_file"
    $tool_bin -q -n $requests -c $concurrent -g $gp $url >> $log;
    echo -e " run $run: $(grep "^Requests per second" $log | tail -1 | awk '{print$4}') reqs/sec" | tee -a $report;
    sleep $intersleep;
  done
  ####### END OF TEST RUNS ############
  # request server info
  f_request_server_info >> $info;
  # compute average reqs/sec
  avg=$(awk -v runs=$runcount '/^Requests per second/ {sum+=$4; avg=sum/runs} END {print avg}' $data_storage/$log_base*)
  echo -e " average: $avg reqs/sec" | tee -a $report;
  echo -e "Generating Gnuplot Script:\t$(basename $gp_test_input)";
  # prepare gnuplot script for test output
  f_gp_test_base $gp_test_output "-n $requests -c $concurrent $url" > $gp_test_input;
  echo -e -n "plot " >> $gp_test_input;
  for datafile in $(ls -1 $data_storage/$gnuplot_base"_"*|sort -n -t_ -k3); do
    run=$(echo $datafile|cut -d_ -f3);
    echo -e "'$(basename $datafile)' using 9 smooth sbezier title 'run $run',\\" >> $gp_test_input;
  done
  # add gnuplot commands to plot info statistics
  f_gp_info_output $info_file $runcount >> $gp_test_input;
  # prepare gnuplot script for info output
  echo -e "Plotting data with Gnuplot to file:\t$gp_test_output";
  cd $data_storage; gnuplot $gp_test_input;
  echo -e "DONE"
}
