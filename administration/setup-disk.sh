#!/bin/bash
# 
# Automatic partitioning script.
# author: alexander kuemmel
#         michael voelske

partitioning() {


    echo Partitioning $1
sudo fdisk $1 <<END
c
u
n
p
1


t
83
w
END

    PART=${1}1
    
    echo Re-reading partition table
    sudo partprobe || exit 1
    
    echo Formatting $PART with ext4
    sudo mkfs.ext4 $PART || exit 1
    
    echo Checking file system on $PART
    sudo fsck -f -y $PART || exit 1
    
    LST=`ls -1 /mnt/ 2>/dev/null`
    if [ -z $LST ]; then 
        LST="0"; 
    fi
    COUNTER=`echo -n "$LST" | tail -c1`
    if [ -z ${COUNTER} ]; then
        COUNTER=1;
    fi
    MNT=/mnt/storage$((COUNTER+1))
    
    echo Creating mount point $MNT
    sudo mkdir -vp $MNT
    
    MNTOPTS="defaults,noatime,relatime,errors=remount-ro,grpid"
    
    echo Attempting to mount file system
    sudo mount -v -o $MNTOPTS -t ext4 $PART $MNT || exit 1
    sudo chgrp -v plugdev $MNT
    sudo chmod g+rwxs $MNT
    
    echo Adding fstab entry. WARNING: duplicates must be removed manually
    UUID=`sudo blkid $PART|awk '{print $2}'|grep -oE '([a-z0-9-]+)'`
    echo -e "#$PART \nUUID=$UUID $MNT ext4 $MNTOPTS 0 2\n" | sudo tee --append /etc/fstab

}

if [ ! $# == 1 ]; then
    echo -e "Usage:\n $0 <disk-device-path>\n $0 -a  'for automatic mode'";
    exit 1;
fi;

if [ $1 == "-a" ]; then
    echo -e "Automatic mode active: all unpartitioned disks are processed"
    devices=(`ls -1 /dev/sd*|awk '/[^a0-9]+$/ {print $0}'`)
    echo Disks in list: ${devices[@]}
    for ix in ${!devices[*]};
    do
        partitioning ${devices[$ix]};
    done;
    exit 0
fi

if [ -b $1 ]; then
    echo -e "All data on $1 will be erased. To avoid this, press CTRL-C now. \nTo proceed, press Enter.";
    read X;
    partitioning $1;
    echo All done.;
fi
