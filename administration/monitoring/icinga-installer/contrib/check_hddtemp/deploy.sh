#!/bin/bash
PATH=/sbin:/bin:/usr/bin:/usr/sbin
if [ $(id -u) -ne 0 ]; then
    echo "Execute this script as root user. Exiting"
    exit 1
fi
if [ -z "$1" ]; then
    echo "No installation directory given. Exiting"
    exit 1
fi
# Number of lines in this script file (plus 1)
SCRIPT_LINES=$(([[SCRIPT_LINES]] + 1))

# Run /bin/sum on your binary and put the two values here
SUM1=[[FIRST_SUM]]
SUM2=[[SECOND_SUM]]
TARGET_DIR="$1"
TARGET_FILE="[[TARGET_FILE]]"
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
    chown icinga.admin "$TARGET_DIR"
    chmod u+rwx,g+rwxs "$TARGET_DIR"
fi
TARGET_PATH="$TARGET_DIR/$TARGET_FILE"
tail -n +$SCRIPT_LINES "$0" | zcat > "$TARGET_PATH"
SUM=`sum $TARGET_PATH` 
ASUM1=`echo "${SUM}" | awk '{print $1}'`
ASUM2=`echo "${SUM}" | awk '{print $2}'`
if [ ${ASUM1} -ne ${SUM1} ] || [ ${ASUM2} -ne ${SUM2} ]; then
    echo "The download file appears to be corrupted. Please download"
    echo "the file again and re-try the installation."
    rm $TARGET_PATH
    exit 1
fi
# setup requirements
yes no|aptitude --assume-yes --without-recommends install hddtemp
chmod u+s /usr/sbin/hddtemp
chown root.admin $TARGET_PATH
chmod u+xs,g+x,o+x $TARGET_PATH
exit 0
# MARKER: DO NOT REMOVE ################### END_OF_SCRIPT #############################################################
