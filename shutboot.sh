#!/bin/bash

# script to schedule a boot after a shutdown, and a restore of previsously scheduled boot

if [[ -z $project_folder ]]; then
    echo "project_folder is not set"
    exit
fi

if [[ -z $password ]]; then
    echo "password is not set"
    exit
fi

if [[ -z $restartdelay ]]; then
    echo "restartdelay is not set"
    exit
fi

if [[ -z $reboot ]]; then
    echo "reboot is not set"
    exit
fi

if [[ -z $debug ]]; then
    echo "debug is not set"
    exit
fi

#exit

pmsched_file="${project_folder}/pmsched.txt"
# restore previously saved wakeorpoweron event
if [[ -f ${pmsched_file} ]]; then
    partial_osa_string=$(cat "${pmsched_file}")
    echo "$(date) : restoring schedule : ${partial_osa_string}"
    if [[ "${partial_osa_string}" != '' ]]; then
        osa_string="do shell script \"pmset repeat ${partial_osa_string}\" password \"${password}\" with administrator privileges"
#echo "osa_string : ${osa_string}"
        sudo osascript -e "${osa_string}"
    fi
    rm -f "${pmsched_file}"
    exit
fi


function getsched {
    # time must be in 24hr format
    sched_time="$(echo ${sched} | cut -d' ' -f 3)"
    ampm=${sched_time: -2}
    if [[ ${ampm: -1} = 'M' ]]; then sched_time="${sched_time%??}"; fi
    sched_mn=$(echo ${sched_time} | cut -d':' -f2)
    sched_hr=$(echo ${sched_time} | cut -d':' -f1)
    if [[ ${ampm} = 'PM' ]]; then (( sched_hr+=12 )); fi
    if [[ ${sched_hr} = '24' ]]; then sched_hr='0'; fi

    # parse to create a "days code"
    sched_days="$(echo ${sched} | cut -d' ' -f 4-)"
    if [[ ${sched_days} = 'every day' ]]; then
        sched_days_code='MTWRFSU'
    elif [[ ${sched_days} = 'weekdays only' ]]; then
        sched_days_code='MTWRF'
    elif [[ ${sched_days} = 'weekends only' ]]; then
        sched_days_code='SU'
    elif [[ ${sched_days} = 'Monday' ]]; then
        sched_days_code='M'
    elif [[ ${sched_days} = 'Tuesday' ]]; then
        sched_days_code='T'
    elif [[ ${sched_days} = 'Wednesday' ]]; then
        sched_days_code='W'
    elif [[ ${sched_days} = 'Thursday' ]]; then
        sched_days_code='R'
    elif [[ ${sched_days} = 'Friday' ]]; then
        sched_days_code='F'
    elif [[ ${sched_days} = 'Saturday' ]]; then
        sched_days_code='S'
    elif [[ ${sched_days} = 'Sunday' ]]; then
        sched_days_code='U'
    fi
}


if [[ ${reboot} -eq 1 ]]; then
    pmsched_string=""
    # save wakepoweron event to restore it after a reboot
    sched=$(pmset -g sched | grep 'wakepoweron at ')
    if [[ ${sched} ]]; then
        getsched
        pmsched_string="${pmsched_string} wakeorpoweron ${sched_days_code} ${sched_hr}:${sched_mn}:00"
#echo "${pmsched_string}"
    fi
    # save shutdown event to restore it after a reboot
    sched=$(pmset -g sched | grep 'shutdown at ')
    if [[ ${sched} ]]; then
        getsched
        pmsched_string="${pmsched_string} shutdown ${sched_days_code} ${sched_hr}:${sched_mn}:00"
#echo "${pmsched_string}"
    fi

    if [[ ! -z ${pmsched_string} ]]; then
#echo "${pmsched_string}"
        echo "${pmsched_string}" >"${pmsched_file}"
    else
        rm -f "${pmsched_file}"
    fi

#exit

    # schedule a poweron event for an autoreboot after a shutdown.
    now=$(date +%s)
    ((restartdelay+=1))
    restart_time="$(date -j -f %s $((now+60*restartdelay)) '+%H:%M'):00"
    echo "$(date) : restarting computer at ${restart_time}"
    echo
    osa_string="do shell script \"pmset repeat wakeorpoweron MTWRFSU ${restart_time}\" password \"${password}\" with administrator privileges"
    osascript -e "${osa_string}"

    if [[ debug -eq 1 ]]; then
        echo "$(date) : reboot! (debug message, not actually rebooting)"
        exit
    fi

    # stop the cron daemon to avoid this script to run again before a complete shutdown
    sudo launchctl unload /System/Library/LaunchDaemons/com.vix.cron.plist
    # halt the computer
    sudo launchctl reboot halt # it seems to be the fastest method
    #sudo /sbin/shutdown -h now
fi


