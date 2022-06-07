# (2.1) Steps taken to create the master image for the contestnet terminal units
---------------------------------------------
* Flashed 2022-04-04-raspios-bullseye-armhf-lite.img.xy image to SD card (8GB MicroSD)

> Used the official Raspberry PI Imager this time
Direct Method _(for reference)_:
```sh
dd bs=4M if=2015-05-05-raspbian-wheezy.img of=/dev/mmcblk0
```

* booted OS on Unit#1

## raspi-config
* set the local to en_US-UTF8 from raspi-config
* set keyboard layout to US from raspi-config
* set default user to kiosk: (see .secrets file)
* set timezone to us central from raspi-config
* set wirless channel localization to US
* set hostname to 'contestnet-unit0
* enabled SSH server
> @TODO should limit it to the support user

*	Extended partition out to 7,000MB using gparted (going to not do this this time)

## Install VIM
> cause VI is terrible, and i couldn't wait 2 steps
```sh
sudo apt install vim
```

## Configure automatic updates
* Install unattended upgrades package
```sh
sudo apt-get install unattended-upgrades apt-listchanges
```
* Updated to remove unused kernel packages and automatically reboot in `/etc/apt/apt.conf.d/50unattended-upgrades`
```sh
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
```

> @TODO have not made up my mind if i should have it send emails on failure

## Create support user
```sh
sudo adduser support
sudo usermod -a -G adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,render,netdev,gpio,i2c,spi support
```

## Install Prerequisites
* packages
```sh
sudo apt install unclutter feh xterm libwww-perl libjson-perl cec-utils chromium-browser ttf-mscorefonts-installer
```
> Previously liblockdev1 and libcec-2.1.0-1 need to be installed as well, now it is included with cec-utils


## Add Default WiFi Configuration
* Copy [wpa_supplicant.conf](./wpa_supplicant.conf) to `/etc/wpa_supplicant/wpa_supplicant.conf`

> @TODO I REALLY need to figure out how to make joining a wifi network more self service on these.....
> 
> Here are some links i found of similar projects:
> * https://www.reddit.com/r/raspberry_pi/comments/5561tp/chromecastlike_connection_wifi_setup_for/
> * https://github.com/jasbur/RaspiWiFi
> * https://github.com/WebThingsIO/gateway-wifi-setup
> * https://www.proqsolutions.com/raspberry-pi/
> * https://github.com/hdemel/RPi-EasyWiFi
> * https://thepi.io/how-to-use-your-raspberry-pi-as-a-wireless-access-point/
>
> I would want it to hook in to the launcher and determine it does not have a wifi connection, and put it in this mode
> and then reboot / restart the sequence once set to go back into the loop and check (and then pass) again so it can start up normal


## Install perl library for getting network interface information and ini read/write module
```sh
sudo cpan
# Autoconfiguration, and accepted all defaults for CPAN
cpan> install IO::Interface::Simple
cpan> install Config::IniFiles
# Updated CPAN
cpan> install CPAN
```
> got an error saying it needed 'inc::latest' as part of the build
> got another message saying it cant check something without CPAN::DistnameInfo
> despite those everything seems fine


## Create Directory structure for contestnet
```sh
sudo mkdir -p /opt/contestnet/bin
sudo mkdir -p /opt/contestnet/etc
sudo mkdir -p /opt/contestnet/lib 
sudo mkdir -p /opt/contestnet/log
sudo mkdir -p /opt/contestnet/var

sudo chmod -R go+w /opt/contestnet
```


## Create directory structure for wireless-monitor
```sh
sudo mkdir -p /opt/wireless-monitor/bin
sudo mkdir -p /opt/wireless-monitor/log

sudo touch /opt/wireless-monitor/log/wireless-monitor.log
```


## Setting the TV configuration

The computer senses display settings on start up, and dynamically configures certain
properties based on what it finds.

This is undesirable in our case since we have a fixed desired configuration and can't
necessarily control the order of operations during startup since remote, restarts are
a very common scenario.

Edit `/boot/config.txt` to force enable the HDMI port regardless of the detected presense of
an HDMI connection

```sh
hdmi_force_hotplug=1
```

When setting up a specific unit we will also be forcing an EDID configuration

Add a commented out line to `/boot/config.txt` to speed up unit configuration

```sh
#hdmi_edid_file=1
```

> when setting a device up you will uncomment this file and either generate
> or select one of the precreated EDID files.
>
> With this setting enabled, it will load the settings from `/boot/edid.dat`

### Creating a TV specific EDID file

when the computer detects a display it collects details about the display such as its frequency,
orientation, dimensions, and capabilities.

You can also store these in a file and direct the computer to use these settings for the display
even if it is not present, which is handy for the display units because we cannot ensure that
the TV is on and detectable when the unit is powered on.

by configuring it to force the settings from file regardless of the presence of the TV
protects against getting odd display settings, so we generate an EDID file
for the TV type and force it on a per unit basis.

To gengerate an EDID file for a display, start the Pi with the display on so it is properly detected
and visually confirm that things look right.

Once set run the following command to generate a display specific EDID file

```sh
sudo tvservice -d /opt/contestnet/etc/edid-[displayname]-[displaysize].dat
```

> Replace [displayname] & [displaysize] with the relevent information
> such as `edid-westinghouse-32.dat`
>
> I have been storing these as they come along for easy remote configuration
> since we can send the appropriate commands to copy the right file into place
> and trigger a restart of the system incase it is needed (it hasn't been to date though) 


## Configure openbox default background color

We set the a [background image](./src/opt/contestnet/background.jpg) that has the SALMON-A-RAMA logo on a grey background
with the contest.net powered by logo in the bottom. When openbox starts there is a short period where the background image
has not loaded yet, and to make it less jarring, we set the background color for openbox to match the background color
of the image that will be loaded quickly after

Edit `/etc/X11/openbox/autostart` to include
```sh
xsetroot -solid "#b0b0b0"
```


## Allow the use of SUDO without password for sudo group members

The remote command component of the worker process is used for running maintenance operations
on the system that will often need to be prefixed with sudo, so the system is set up to let those
happen.

```sh
sudo visudo
```

```sh
%sudo ALL=(ALL) NOPASSWD: ALL
```



## Copy Unit Files (from host system)

For these steps the system needs to be shut back down and the OS drive moved to a source system
that has this and the other repositories checked out and current on it.

After moving the needed files onto the OS drive the remainder of the setup will take place
back on the running system.


### Contestnet

```sh
SourceDir=~/displayunits
TargetDir=/media/jlh/rootfs/opt/contestnet

sudo cp $SourceDir/configuration/src/opt/contestnet/etc/* $TargetDir/etc/
sudo cp $SourceDir/launcher/launcher $TargetDir/bin/
sudo cp $SourceDir/worker/Logger.pm $TargetDir/lib/
sudo cp $SourceDir/worker/worker $TargetDir/bin/
```

This should leave you with a directory structure such as
```sh
# tree opt/contestnet/
opt/contestnet/
├── bin
│   ├── launcher
│   ├── omxplayer-loop
│   └── worker
├── etc
│   ├── background.jpg
│   ├── contestnet.conf
│   ├── edid-panasonic-50.dat
│   ├── edid-westinghouse-32.dat
│   └── task.ini
├── lib
│   └── Logger.pm
├── log
└── var

5 directories, 9 files
```



### Wireless-Monitor

> setup will be completed bac


```sh
# tree opt/wireless-monitor/
opt/wireless-monitor/
├── bin
│   └── wireless-monitor
└── log

2 directories, 1 file
```



### Loopable OMX Player

> copy the three files, two are temp locations



## Complete Wireless-Monitor Setup


## Complete Loopable OMX Player



## Not updated yet

	




# 	Installed loopable version of omxplayer to /opt/omxplayer (tarball must be unzipped on machine)
#	Source Files
#		omxplayer-loop-multifile-bin.tar.gz
#		omxplayer
#		omxplayer-loop
sudo cp $SourceFiles/omxplayer-loop-multifile-bin.tar.gz /opt/
sudo tar -xzvf omxplayer-loop-multifile-bin.tar.gz
sudo mv omxplayer-dist omxplayer
sudo mv /opt/omxplayer/usr/bin/omxplayer /opt/omxplayer/usr/bin/omxplayer.original
sudo cp $SourceFiles/omxplayer /opt/omxplayer/usr/bin/omxplayer
sudo chmod ugo+x /opt/omxplayer/usr/bin/omxplayer
sudo chown -R run:users /opt/omxplayer
sudo cp $SourceFiles/omxplayer-loop /opt/contestnet/bin/
sudo chmod ugo+x /opt/contestnet/bin/omxplayer-loop

#	Installed utility to monitor the wireless link and attempt to bounce if it goes down
sudo mkdir /opt/wireless-monitor/bin
sudo mkdir /opt/wireless-monitor/log
sudo touch /opt/wireless-monitor/log/wireless-monitor.log
sudo cp $SourceFiles/wireless-monitor /opt/wireless-monitor/bin/
sudo chmod ugo+x /opt/wireless-monitor/bin/wireless-monitor
sudo chown -R run:users /opt/wireless-monitor

#	Added entry to root users crontab to run wireless-monitor every 5 minutes
sudo su -
crontab -e
#	# */5 * * * * /opt/wireless-monitor/bin/wireless-monitor
#	Added entry commented out so it does not run in the base image
#	it will need to be enabled as part of the unit setup

#	Set the run user to auto login on startup
#	@/etc/inittab
#	comment out line for tty1 and add new line
#	#oldline
#	### ----------------------- Auto Login Run User ----------------------- ###
#	1:2345:respawn:/bin/login -f run tty1 </dev/tty1 >/dev/tty1 2>&1
#	### ------------------------------------------------------------------- ###

#	Set the run user to run launcher on login
#	@/home/run/.bashrc
#	### -------------- Start Contestnet Terminal Application -------------- ###
#	#xinit /opt/contestnet/bin/launcher
#	#exit
#	### ------------------------------------------------------------------- ###

# Created contestnet-unit-master-2.0-r002.img using ubuntu disk utility (garbage)
# Created contestnet-unit-master-2.0-r003.img using dd

# 	Set permissions on /opt/contestnet and /opt/wireless-monitor so group can write
sudo chmod -R g+w /opt/contestnet
sudo chmod -R g+w /opt/wireless-monitor

#	Changed version of worker to 1.0.1 in base
#	Updated task.ini so the default resource does not use HTTPS

# Created contestnet-unit-master-2.0-r004.img using dd



