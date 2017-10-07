# watchdog.sh + shutdoot.sh

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
Marc.

## Operating systems
This has only been tested on macOS 10.10.5 - 10.12

## Prepare Computer
Copy the following commands in to the terminal app.

`defaults write com.apple.CrashReporter DialogType none`<br />
(If you never want to see the crash report dialogs. log out and in again)

`defaults write -g ApplePersistence -bool no`<br />
(prevents apps from reopening after restart)

## Setup
### Task 1: Add your user to the wheel group
Open a terminal, then type:<br />
`sudo dscl . append /Groups/wheel GroupMembership admin`<br />
(replace USER by your user, like admin)<br />
Restart your session (logoff+login, or reboot)

### Task 2: Grant passwordless sudo access to the wheel group
Open a terminal, then log at root with: `sudo su -`<br />
(keep it open as root to fix things in case of errors)<br />
Make a backup of the original sudoers file:<br />
`cp /etc/sudoers /etc/sudoers.orig`<br />
Edit the sudoers file (with great care):<br />
`nano -w /etc/sudoers`<br />
(uncomment this line by deleting the first "#"):<br />
**# %wheel ALL=(ALL) NOPASSWD: ALL**<br />
if it is not present just add it to the end of the file, like on a hackintosh<br />

exit nano via **control x**, then type **y**, hit **enter**<br />
Open a new terminal, for testing the change made to the sudoers:<br />
`sudo su -`

#### If it doesn't work:
`sudo dseditgroup -o edit -a MYUSERNAME  -t user wheel`<br />
(will add this user to the wheel group)<br />
`id shows the group`<br />
then restore the sudoers file from its backup if nothing worked.<br />
with `cp -f /etc/sudoers.orig /etc/sudoers`

### Task 3: Install the watchdog script
I usually copy wathdog.sh, shutboot.sh and the log folder where my main app is located.<br />
But you can place them anywhere.

Make watchdog.sh executable:<br />
`chmod 755 PATHtoSCRIPThere/watchdog.sh`

Edit watchdog.sh:

Enter the path where all your apps live.<br />
`project_folder="/Users/admin/Desktop/zoomP"`

Enter you admin password.<br />
`password="YOUR PASSWORD HERE"`

Enter your all the app paths.<br />
`apps[0]="blob/bin/zoomP.app/Contents/MacOS/blob"`<br />
`apps[1]="blob2/bin/zoomP.app/Contents/MacOS/blob2"`

Enter path to all heartbeat.txt files.<br />
`beats[0]="zoom_pavilion_faceTracker/bin/data/runLogs/heartbeat.txt"`<br />
`beats[1]="face2/bin/data/runLogs/heartbeat.txt"`

Make any required changes to the script.<br />
Make sure that the " are straight ones not the angled type of quotation marks.<br />
Then test it manually to make sure it works as expected. For example:<br />
`/Users/YouruserName/Desktop/watchdog.sh`

### Task 4: Schedule the watchdog to run every minute via cron

In the terminal type `exit` to exit sudo superuser. Otherwise the cron job you are going to create will be as superuser. This might cause problems if your restarted apps link to libraries that were only install as admin user.

Edit your crontab via the terminal:<br />
`crontab -e` to enter edit mode<br />
press **i** to allow insert mode<br />
trype or copy past the cron job.<br />
mine looks often like this<br />
***/1 * * * * /Users/admin/Desktop/OF/watchdog.sh >> /Users/admin/Desktop/OF/log/watchdog.log**<br />
press **esc** to exit insert mode<br />
press captial **ZZ** to exit crontab<br />
`crontab -l` to display all cron jobs

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
