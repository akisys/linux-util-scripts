#!/bin/bash
#
# Renames otf/ttf font files within a given directory according to the given font label encoded
# in each file, while keeping the directory structure as it is.
#
# author: akisys _at_ alexanderkuemmel.com

# bail on any error
set -e

# Argument = -d DIRNAME -l USEDLABEL -r -v

usage()
{
  echo """
  Needs packages with commands: rename, fc-query

  Usage: $0 options
  
  OPTIONS:
     -h         Show this message
     -d <DIR>   Directory to scan
     -l <LABEL> Use this label for renaming [e.g. fullname, postscriptname]
     -r 1|0     1: Rename files | 0: List files with new name
     -v         Verbose
  """
}

if [ -z $1 ]; then
  usage
  exit
fi

STARTDIR=
EXTRACT_LABEL=
RENAME_FILES=
VERBOSE=
while getopts “hd:l:rv” OPTION
do
  case $OPTION in
    h)
        usage
        exit 1
        ;;
    d)
        STARTDIR=$OPTARG
        ;;
    l)
        EXTRACT_LABEL=$OPTARG
        ;;
    r)
        RENAME_FILES=1
        ;;
    v)
        VERBOSE=1
        ;;
    ?)
        usage
        exit
        ;;
  esac
done

if [ -z ${STARTDIR} ] || [ -z ${EXTRACT_LABEL} ]; then
  usage
  exit
fi

fontext_pattern="[ot]tf"


OIFS=$IFS
IFS=$(echo -en "\n\b")

fontlist=(`find ${STARTDIR} -type f -iname "*$fontext_pattern"`)

rename_opts=
if [ $VERBOSE ]; then
  rename_opts+="-v";
fi
if [ -z $RENAME_FILES ]; then
  rename_opts+=" -n";
fi
for f in ${fontlist[*]};
do
  label=$(fc-query --format="%{$EXTRACT_LABEL}\n" "$f")
  if [ $VERBOSE ]; then
    echo -e "file: $f\t label: $label\trenaming opts: '$rename_opts'";
  fi
  if [ -z $label ]; then
    continue
  fi
  (
    export IFS=$OIFS
    dirname=`dirname $f`
    rename $rename_opts "s/^(.*\/)(.*)(\.$fontext_pattern)\$/\$1\/$label\$3/" "$f"
  )
done;
IFS=$OIFS
