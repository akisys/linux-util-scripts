#!/bin/bash
#
# Exports VirtualBox machines to compressed Box files, usable with vagrant.
#
# author: akisys _at_ alexanderkuemmel.com

self=$(basename $0)

function usage() {
  echo """
  Usage of $self:
  
  $self <virtualbox_name>
  
  The script exports the given VirtualBox VM to a compressed <virtualbox_name>.box file in the current directory!
  Use that file in your Vagrantfile setup to initialize new Vagrant machines.
  """
}

## check for additional <virtualbox_name> parameter
if [ -z $1 ]; then
  usage;
  exit -1;
fi

vboxname="$1"

## check for virtualbox information and extract first seen MAC address
vminfoMAC=$(VBoxManage showvminfo $vboxname|egrep -i "nic 1"|tr -d "[:blank:][:cntrl:]"|cut -d, -f1|cut -d: -f3)

if [ -z $vminfoMAC ]; then
  usage;
  exit -1;
fi;

## vagrant compatible json template
metadata_json='{
  "provider" : "virtualbox"
}';

## vagrant 1.1 compatible Vagrantfile template
vagrantfile="# -*- mode: ruby -*-
# vim: set ft=ruby :

Vagrant.configure(\"2\") do |config|
  config.vm.base_mac = \"${vminfoMAC}\"
end"

## create temporary directory in /tmp/
exportdir=$(mktemp -d)

## save current directory, because we're going to change folders
outputdir=$PWD

## virtualbox specific vm export command
exportcmd="VBoxManage export ${vboxname} --ovf10 -o ${exportdir}/box.ovf"

## bundle everything in a tar archive
archivecmd="tar -c -C $exportdir -f - *"

## and compress it with maximum compression
compresscmd="gzip -9 -c"

## write the preliminary files for the archive
echo "$metadata_json" > ${exportdir}/metadata.json
echo "$vagrantfile" > ${exportdir}/Vagrantfile

## execute export command and continue with archiving and compression only if that succeeded
$exportcmd && $(cd $exportdir && $archivecmd|$compresscmd > $outputdir/${vboxname}.box && cd $outputdir)

## delete temporary directory
rm -rf ${exportdir}

