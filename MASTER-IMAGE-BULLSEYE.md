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


## Installed perl library for getting network interface information and ini read/write module
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

## Copy Unit Files (from host system)


#	Set HTMI output to be active even if HDMI connections are not detected
#	@/boot/config.txt
#	hdmi_force_hotplug=1

#	Added a commented line in /boot/config.txt to enabled use of pregenerated edid.dat file
#	@/boot/config.txt
#	#hdmi_edid_file=1
#	
#	To generate an edid file for a display, start the Pi with the display on so it is properly detected
#	then run `sudo tvservice -d /opt/contestnet/etc/edid-[displayname]-[displaysize].dat`
# 	uncomment the hdmi_edid_file=1 line and copy the edid file to /boot/edid.dat

#	Created Contesnet application structure
sudo mkdir /opt/contestnet/bin
sudo mkdir /opt/contestnet/etc
sudo mkdir /opt/contestnet/lib 
sudo mkdir /opt/contestnet/log
sudo mkdir /opt/contestnet/var
sudo chmod -R go+w /opt/contestnet
#	Copied in contestnet application files from 1.0 source
#	bin/
#		launcher
#		omxplayer-loop
#		worker
#		worker.restore (this should be removed)
#	etc/
#		background.jpg
#		contestnet.conf
#		edid-panasonic-50.dat
#		edid-westinghouse-32.dat
#		task.ini
#	lib/
#		Logger.pm
#	log/
#	var/
	

#	Added setting of default background color for openbox
#@/etc/X11/openbox/autostart
#	xsetroot -solid "#b0b0b0"

#	Installed partial-software root certificate as trusted CA
sudo mkdir /usr/share/ca-certificates/partial-software
sudo cp partial-software-ca.crt /usr/share/ca-certificates/partial-software/
sudo dpkg-reconfigure ca-certificates 
#	Select partial-software as trusted in the list
#	(no longer need to run update-ca-certificates after, it happens automatically)

#	Set ability for all members of sudo group to run sudo commands without password
sudo visudo
#	%sudo ALL=(ALL) NOPASSWD: ALL

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



