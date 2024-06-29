#!/bin/bash
#
# dynamic motd script by Oliver Haessler <oliver@redhat.com>
# Modified by: Travis Michette <tmichett@redhat.com>
#
# License: GPLv2

USER=`whoami`
HOSTNAME=`uname -n`
DF_ROOT=`df -Ph | grep -w / | awk '{print $4}' | tr -d '\n'`
DF_HOME=`df -Ph | grep home | awk '{print $4}' | tr -d '\n'`
DF_VIRTUALMACHINES=`df -Ph | grep VirtualMachines | awk '{print $4}' | tr -d '\n'`

if [ -f /usr/bin/systemd-loginctl ];
then
    USERS=`systemd-loginctl list-users | grep listed | awk -F" " '{ print $1 }'`
else
    USERS=`users | wc -w`
fi

MEMORY1=`free -t -m | grep "Mem" | awk '{print $3" MB";}'`
MEMORY2=`free -t -m | grep "Mem" | awk '{print $2" MB";}'`
PSA=`ps -Afl | wc -l`
SWAP=`free -m | tail -n 1 | awk '{print $3}'`

#System uptime
uptime=`cat /proc/uptime | cut -f1 -d.`
upDays=$((uptime/60/60/24))
upHours=$((uptime/60/60%24))
upMins=$((uptime/60%60))
upSecs=$((uptime%60))

#System load
LOAD1=`cat /proc/loadavg | awk {'print $1'}`
LOAD5=`cat /proc/loadavg | awk {'print $2'}`
LOAD15=`cat /proc/loadavg | awk {'print $3'}`

# Hardware info
Manufacturer=`cat /sys/devices/virtual/dmi/id/chassis_vendor`
MachineType=`cat /sys/devices/virtual/dmi/id/product_name`
MachineModel=`cat /sys/devices/virtual/dmi/id/product_version`

# check if user is root, as you need root permissions to read the product_serial files
if [ "$USER" == "root" ]; then
    SerialNumber=`cat /sys/devices/virtual/dmi/id/product_serial`
else
    SerialNumber="Only accessible by root"
fi

# set Release
RELEASE=`cat /etc/redhat-release`

# set tput values
reset=$(tput sgr0)
bold=$(tput bold)
red=$(tput setaf 1)
magenta=$(tput setaf 5)

# file to check for root access
sudofile="/etc/sudoers.d/$USER"

# clear the screen (clear is actually sending a escape code that shows in the screen. The Echo line below is preventing this
echo -en "\e[H\e[2J"

echo "==================================="$bold""$magenta"User  Data"$reset"===================================
 - Hostname....: $HOSTNAME
 - Release.....: $RELEASE
 - Users.......: Currently $USERS user(s) logged on
================================="$bold""$magenta"Hardware  Data"$reset"=================================
 - Manufacturer:................: $Manufacturer
 - Machine Type:................: $MachineType
 - Machine Model:...............: $MachineModel
 - Serial Number:...............: $SerialNumber
=================================="$bold""$magenta"System  Data"$reset"==================================
 - CPU usage....................: $LOAD1, $LOAD5, $LOAD15 (1, 5, 15 min)
 - Memory used..................: $MEMORY1 / $MEMORY2
 - Swap in use..................: $SWAP MB
 - System uptime................: $upDays days $upHours hours $upMins minutes $upSecs seconds
 - Disk space Root..............: $DF_ROOT remaining
 - Disk space Home..............: $DF_HOME remaining
================================================================================"

# check if sudo file exists and user has sudo access
if [ -s $sudofile ]; then
    if [[ $(grep -qE '#.*ALL' $sudofile)$? = 1 ]] && [[ $(grep -qE 'ALL' $sudofile)$? = 0 ]]; then
        echo ""$bold""$red"                             User has sudo access!!"$reset"
================================================================================"
    fi
fi
