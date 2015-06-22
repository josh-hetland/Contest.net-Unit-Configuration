#!/bin/bash
##################################################################
# A Project of TNET Services, Inc
#
# Title:     WiFi_Check
# Author:    Kevin Reed (Dweeber)
#            dweeber.dweebs@gmail.com
# Project:   Raspberry Pi Stuff
#
# Copyright: Copyright (c) 2012 Kevin Reed <kreed@tnet.com>
#            https://github.com/dweeber/WiFi_Check
#
# Purpose:
#
# Script checks to see if WiFi has a network IP and if not
# restart WiFi
#
# Uses a lock file which prevents the script from running more
# than one at a time.  If lockfile is old, it removes it
#
# Instructions:
#
# o Install where you want to run it from like /usr/local/bin
# o chmod 0755 /usr/local/bin/wifi-check
# o Add to crontab
#
# Run Every minute
# * * * * * /usr/local/bin/wifi-check
#
##################################################################
# Settings
# Where and what you want to call the Lockfile
lockfile='/var/run/wifi-check.pid'
# Where error occurances are written
logfile='/var/log/wifi-check.log'
# Which Interface do you want to check/fix
wlan='wlan0'
##################################################################

# Check to see if there is a lock file
if [ -e $lockfile ]; then
    # A lockfile exists... Lets check to see if it is still valid
    pid=`cat $lockfile`
    if kill -0 &>1 > /dev/null $pid; then
        # Still Valid... lets let it be...
        #echo "Process still running, Lockfile valid"
        exit 1
    else
        # Old Lockfile, Remove it
        #echo "Old lockfile, Removing Lockfile"
        rm $lockfile
    fi
fi
# If we get here, set a lock file using our current PID#
#echo "Setting Lockfile"
echo $$ > $lockfile

# We can perform check (removed positive information, only concerned with errors)
if ! ifconfig $wlan | grep -q "inet addr:" ; then
	echo "[ $(date '+%Y-%m-%d %T') ] $wlan inteface has disconnected, attempting to reconnect" >> $logfile
	ifdown $wlan
	sleep 5
	ifup --force $wlan
	## There isnt a check to see if it came up or not though..
fi
 
# Check is complete, Remove Lock file and exit
#echo "process is complete, removing lockfile"
rm $lockfile
exit 0

##################################################################
# End of Script
##################################################################