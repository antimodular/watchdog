#watchdog.sh + shutdoot.sh

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

`defaults write com.apple.CrashReporter DialogType none`<br>\r\n
(If you never want to see the crash report dialogs. log out and in again)

`defaults write -g ApplePersistence -bool no`
(prevents apps from reopening after restart)

## Setup
### Task 1: Add your user to the wheel group
Open a terminal, then type:<br />
`sudo dscl . append /Groups/wheel GroupMembership admin`  
(replace USER by your user, like admin)<br />
Restart your session (logoff+login, or reboot)

### Task 2: Grant passwordless sudo access to the wheel group
Open a terminal, then log at root with: `sudo su -`
(keep it open as root to fix things in case of errors)
Make a backup of the original sudoers file:
`cp /etc/sudoers /etc/sudoers.orig`
Edit the sudoers file (with great care):
`nano -w /etc/sudoers`
(uncomment this line by deleting the first "#"):
**# %wheel ALL=(ALL) NOPASSWD: ALL**
if it is not present just add it to the end of the file, like on a hackintosh

exit nano via **control x**, then type **y**, hit **enter**
Open a new terminal, for testing the change made to the sudoers:
`sudo su -`

#### If it doesn't work:
`sudo dseditgroup -o edit -a MYUSERNAME  -t user wheel`
(will add this user to the wheel group)
`id shows the group`
then restore the sudoers file from its backup if nothing worked.
with `cp -f /etc/sudoers.orig /etc/sudoers`

### Task 3: Install the watchdog script
I usually copy wathdog.sh, shutboot.sh and the log folder where my main app is located.
But you can place them anywhere.

Make watchdog.sh executable:
`chmod 755 PATHtoSCRIPThere/watchdog.sh`

Edit watchdog.sh:

Enter the path where all your apps live.
`project_folder="/Users/admin/Desktop/zoomP"`

Enter you admin password.
`password="YOUR PASSWORD HERE"`

Enter your all the app paths.
`apps[0]="blob/bin/zoomP.app/Contents/MacOS/blob"`
`apps[1]="blob2/bin/zoomP.app/Contents/MacOS/blob2"`

Enter path to all heartbeat.txt files.
`beats[0]="zoom_pavilion_faceTracker/bin/data/runLogs/heartbeat.txt"`
`beats[1]="face2/bin/data/runLogs/heartbeat.txt"`

Make any required changes to the script.
Make sure that the " are straight ones not the angled type of quotation marks.
Then test it manually to make sure it works as expected. For example:
`/Users/YouruserName/Desktop/watchdog.sh`

### Task 4: Schedule the watchdog to run every minute via cron

In the terminal type `exit` to exit sudo superuser. Otherwise the cron job you are going to create will be as superuser. This might cause problems if your restarted apps link to libraries that were only install as admin user.

Edit your crontab via the terminal:
`crontab -e` to enter edit mode
press **i** to allow insert mode
trype or copy past the cron job.
mine looks often like this
***/1 * * * * /Users/admin/Desktop/OF/watchdog.sh >> /Users/admin/Desktop/OF/log/watchdog.log**
press **esc** to exit insert mode
press captial **ZZ** to exit crontab
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
**-bash: /Users/admin/Desktop/zoomP/watchdog.sh: /bin/bash^M: bad interpreter: No such file or directory**
The file format of your .sh is wrong. Make file unix (LF) via the great app [BBedit](https://www.barebones.com/products/bbedit/)
