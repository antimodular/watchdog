#!/bin/bash
export XAUTHORITY=/home/pi/.Xauthority
export DISPLAY=:0.0
# watchdog script to restart applications if they're not running
# save it in your project folder

project_folder="/home/pi/openFrameworks/apps/remotePulse"

# touch a temp file to "heartbeat" this script (useful for debugging)
touch "${project_folder}/$(basename $0)-heartbeat.txt"

# uncomment to exit this script (useful for debugging cron)
# exit

# set to 1 to print debug messages
debug=1

# exit if before startupdelay seconds after finder start time.
startupdelay=120
# note: boot time is "kernel" boot time, not "finder" boot time.

# delay in minutes for a scheduled restart
restartdelay=2

# user password (for applescript administrative permission)
password="myPASSWORD"

# partial paths of the applications to monitor (relative to the project folder)
# (the binary is inside the app):
# apps[0]="remotePulse/bin/remotePulse"
apps2="remotePulse/bin/remotePulse"
echo "$apps2"
# partial paths of their corresponding heartbeat files:
beats2="remotePulse/bin/data/runLogs/heartbeat.txt"
echo "$beats2"

# the short heartbeat delay:
shortdelay=15
# If the heartbeat of an app was modified more than shortdelay seconds
# before the script is executed, the application will be killed
# and restarted. The heartbeat files must be updated every x secs,
# where x is lower than half of shortdelay (ex: 10 for shortdelay=30)
# example of a simple update command:
# touch '/tmp/beat.txt'

# the long heartbeat delay:
longdelay=90
# If the heartbeat of an app was modified more than longdelay seconds
# before the script is executed, the computer will be restarted

# this script must be used from your "crontab":
# edit the crontab with this command:
# EDITOR=nano crontab -e
# and insert this line:
# */2 * * * * $HOME/bin/watchdog.sh 1>> $HOME/log/watchdog.log
# once the crontab is saved, it will execure each 2 minutes.
# to disable it, comment the line (with #) using the crontab editor
# important: create the log file with:
# mkdir -p ~/log && touch ~/log/watchdog.log
# the log file will keep a journal of the actions


# nothing to change below this line

eventoccured=0
export reboot=0
export project_folder
export debug
export restartdelay
export password

if [[ ${debug} -eq 1 ]]; then
echo "$(date): ping!"
fi


#$(dirname $0)/shutboot.sh


# uptime in seconds; exit if lower than startupdelay

# uptime of the kernel (deprecated in favor of Finder uptime)
# upsecs=$(/usr/sbin/sysctl -n kern.boottime | cut -d '=' -f2 | cut -d ',' -f1 | tr -d '[:space:]')


#~ echo "${finderh}:${finderm}:${finders}"
#upsecs=$((3600*10#${finderh} + 60*10#${finderm} + 10#${finders}))
# upsecs=`awk '{print $0/60;}' /proc/uptime`;
upsecs_float=`awk '{print $1;}' /proc/uptime`;
upsecs=${upsecs_float%.*}
# 

if [[ ${debug} -eq 1 ]]; then
echo "$(date) : upsecs =  $upsecs"
echo "$(date) : startupdelay =  $startupdelay"

fi

# -lt means less than
#if [[ ${debug} -eq 1 ]]; then
#    echo "$(date) : Finder started ${upsecs} seconds ago"
#fi

if [[ ${upsecs} -lt ${startupdelay} ]]; then 
if [[ ${debug} -eq 1 ]]; then
echo "$(date) : upsecs <  startupdelay so let wait until PI has been running for a while"

fi
exit; 
fi


# main loop to monitor all applications
# for (( i=0; i<=$(( ${#apps[*]} -1 )); i++ )); do
app="${project_folder}/${apps2}"
name="$(basename ${app})"
beat="${project_folder}/${beats2}"

if [[ ${debug} -eq 1 ]]; then
echo "$(date): app $app"
echo "$(date): name $name"
echo "$(date): beat $beat"
fi

# pid of the application
pidofapp=$(ps ax | grep "${app}" | grep -v grep | cut -c1-6 | tr -d '[:space:]')
if [[ ${debug} -eq 1 ]]; then
echo "$(date): pid of app $name = $pidofapp"
fi

# check if app should be started
startapp=0
if [[ ${pidofapp} -gt 0 ]]; then
# echo "pid of \"${name}\" : ${pidofapp}"
# continue if there's no heartbeat
if [[ ! -f "${beat}" ]]; then
echo "${name} : no beat yet: ${beat}"
continue
fi

# get modification delay of the heartbeat
eval $(stat -s "${beat}")
lastmod=$(($(date +%s)-${st_mtime}))

if [[ ${debug} -eq 1 ]]; then
echo "$(date): lastmod of beat file $lastmod"
fi

# check if computer should be restarted
if [[ ${lastmod} -gt ${longdelay} ]]; then

if [[ ${debug} -eq 1 ]]; then
echo "$(date): computer should be restarted"
fi

export reboot=1
break
fi

# echo "$name, $lastmod, ${pidofapp}"
# check if app should be killed and restarted
if [[ ${lastmod} -gt ${shortdelay} ]]; then
sudo kill -9 ${pidofapp}
sleep 1
echo "$(date) : killed \"${name}\" with PID ${pidofapp}"
startapp=1
fi
else
startapp=1
fi

# start the application
if [[ ${startapp} -eq 1 ]]; then
echo "$(date) : starting \"${name}\""
#"${app}" 1>/dev/null 2>/dev/null &
sleep 2
echo "name= ${name}"
#osascript -e 'activate application "${name}"'
sudo /home/pi/openFrameworks/apps/remotePulse/remotePulse/bin/remotePulse
sleep 2
eventoccured=1
echo "should have called sudo app"
fi

#done

# $(dirname $0)/shutboot.sh

if [[ ${eventoccured} -eq 1 ]]; then echo; fi


