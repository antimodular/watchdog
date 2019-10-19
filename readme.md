# watchdog.sh + shutboot.sh

## Introduction
### Why:
I often use USB cameras for our installations. Once in a while these cameras behave badly and either never reconnect or make the main app crash. We needed a way to restart crashed apps, kill frozen apps and reboot the computer if nothing else helped.
In case of the USB camers a simple reboot does not help, since the power to them never gets cut. So we worte shutboot.sh, which shuts the computer down, waits a few minutes and then starts the computer.

### What:
This is a shell script that can be placed anywhere you want.
A cron job is set up which run the watchdog.sh every minute.

The watchdog.sh monitors if one or multiple apps are running.
If any of those apps are not running they get restarted.
The watchdog.sh also checks the last modification date/time of a heartbeat.txt file. This file get's updated by your main app. If this file was not updated in the last `shortdelay` seconds  the script assumes your app froze. It will try to `kill -9` your app and restart it.
If the heartbeat file was not updated in the last `longdelay` seconds the computer get shutdown. Just before the shutdown happens shutboot.sh sets up the computer to start again in `restartdelay` minutes.

### Who:
[Marc](https://github.com/marc-antimodular).

## Operating systems
This has only been tested on macOS 10.12-10.14

## Prepare Computer
Copy the following commands in to the terminal app.

`defaults write com.apple.CrashReporter DialogType none`<br />
(If you never want to see the crash report dialogs. log out and in again)

`defaults write -g ApplePersistence -bool no`<br />
(prevents apps from reopening after restart)

## Setup
read watchdog install with launchd.txt
or watchdog install with crontab.txt

## Heartbeat
I usually add this code to my openframeworks.cc app, to update the heartbeat.txt file
`
if(ofGetElapsedTimef() - logTimer > 2){
    logTimer = ofGetElapsedTimef() ;
    ofBuffer buf(ofGetTimestampString());
    ofBufferToFile("runLogs/heartbeat.txt", buf);
}
`
That's it!


## Troubleshooting
**-bash: /Users/admin/Desktop/zoomP/watchdog.sh: /bin/bash^M: bad interpreter: No such file or directory**<br />
The file format of your .sh is wrong. Make file unix (LF) via the great app [BBedit](https://www.barebones.com/products/bbedit/)
