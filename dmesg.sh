#!/bin/bash
#set -x

# See if timestamps are enabled for dmesg
ts_enabled=`cat /sys/module/printk/parameters/time | tr '[A-Z]' '[a-z]' | sed -e 's/1/y/g'`

if [ "${ts_enabled}" != "y" ]; then
    echo "Y" > /sys/module/printk/parameters/time
fi

# See if dmesg supports timestamps
my_dmesg=`which dmesg 2> /dev/null`

if [ "${my_dmesg}" != "" ]; then
    ${my_dmesg} -T > /dev/null 2>&1
    
    if [ ${?} -ne 0 ]; then
        my_epoch=`date +%s`
        my_uptime=`cat /proc/uptime | awk '{print $1}'`
        my_up_epoch=`echo "${my_epoch}-${my_uptime}" | bc -l`
    
        stdbuf -oL ${my_dmesg} | while read line ; do
            timestamp=`echo "${line}" | egrep "^\[*.*\]\ " | awk '{print $2}' | sed -e 's/[^0-9\.]//g'`
    
            if [ "${timestamp}" != "" ]; then
                normalized_timestamp=`echo "${my_up_epoch}+${timestamp}" | bc -l`
                hr_time=`date -d @${normalized_timestamp} +"%c"`
                echo "${line}" | sed -e "s/^\[*.*\]\ /\[${hr_time}\]\ /g"
            else
                echo "${line}"
            fi
    
        done 
    
    else
        ${my_dmesg} -T
    fi

fi
