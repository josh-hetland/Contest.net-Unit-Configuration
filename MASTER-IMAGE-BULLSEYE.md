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
Unattended-Upgrade::Automatic-Reboot-WithUsers "true";
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
sudo apt install unclutter feh xterm libwww-perl libjson-perl cec-utils chromium-browser ttf-mscorefonts-installer openbox vlc xserver-xorg xserver-xorg-legacy xinit
```
> Previously liblockdev1 and libcec-2.1.0-1 need to be installed as well, now it is included with cec-utils


## Reconfigure the xserver-xorg-legacy Wrapper

The new defaults for X11 mean you can only run clients under certain configurations for security purposes.
After hours of reading on how to do it "the right way" with no clear guide or end in sight, i stumbled across
a forum post saying to reconfigure the legacy wrapper for SETGUID support.

> I set the first value in this configuration by running `dpkg-reconfigure xserver-xorg-legacy` and selecting "Anybody"
> having edited the file afterwards should keep it as is if the package is patched in the future (i hope)

Edit `/etc/X11/Xwrapper.config`:

```sh
allowed_users=anybody
needs_root_rights=yes
```


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


Edit the driver for backwards compatibility

```sh
dtoverlay=vc4-fkms-v3d
```

> The default in the image is `vc4-kms-v3d` which makes the `tvservice` command stop working
> there are alternatives but it needs to be tested on all of the TV models, so for now
> we are keeping it in compatibility mode, though this might be unviable by the next major
> debian release


### Creating a TV specific EDID file

when the computer detects a display it collects details about the display such as its frequency,
orientation, dimensions, and capabilities.

You can also store these in a file and direct the computer to use these settings for the display
even if it is not present, which is handy for the display units because we cannot ensure that
the TV is on and detectable when the unit is powered on.

by configuring it to force the settings from file regardless of the presence of the TV
protects against getting odd display settings, so we generate an EDID file
for the TV type and force it on a per unit basis.

To generate an EDID file for a display, start the Pi with the display on so it is properly detected
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

## Shrink the rootfs partition down to 4GB

To make it easier to unpack onto more disk sizes, the filesystem can be shrunk down to
a smaller size that will fit on more disks

> though all of them are 32gb+ now so this doesn't matter as much as it used to

From a linux system, size the rootfs partition down to 4096Mib using GParted



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

sudo touch $TargetDir/log/contestnet.log
```

This should leave you with a directory structure such as
```sh
# tree opt/contestnet/
opt/contestnet/
├── bin
│   ├── launcher
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

5 directories, 8 files
```



### Wireless-Monitor

In the first year it was observed that a number of the units would lose their connection at various times
during the day and I ended up taking a lot of support calls from the remote weigh in ports where i had to explain
the process of force rebooting the display unit to get it to refresh its network driver.

To account for this situation, this wireless-monitor utility was created which will watch for a loss of connection
and initiate a network service refresh to try and bring it back onto the network.

Its run out of the crontab every 5 minutes so that any offline events are addressed quickly

> This step is just copying the utility to the filesystem, we'll complete its setup back on the running OS


With bullseye the commands are different and this may need to be tested a bit more to get it right

`ip addr show wlan0` 

```sh
3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP>
    link/ether [mac address]
    inet 192.168.1.36/24
```

`sudo ip link set wlan0 down`

`sudo ip link set wlan0 up`

hostname -I also just prints the IP address, or nothing when the interface is down (but what about disconnected?)

otherwise the command can be changed to:
```sh
ip addr show wlan0 | grep 'inet ' | awk '{print $2}'
```


```sh
# tree opt/wireless-monitor/
opt/wireless-monitor/
├── bin
│   └── wireless-monitor
└── log

2 directories, 1 file
```


## Complete Wireless-Monitor Setup

> Back on the running OS

Set the wireless-monitor script as executable and change the ownership to the
kiosk user so it can be used directly by that user during normal execution

```sh
sudo chmod +x /opt/wireless-monitor/bin/wireless-monitor
sudo chown -R kiosk:users /opt/wireless-monitor
sudo chmod -R g+w /opt/wireless-monitor 
```

Set up the crontab for the root user to run the wireless monitor on a short interval
so if we lose wifi (which seems to be pretty common where these things end up sitting)
it will attempt to bounce the network interface to bring it back up

> The line is commented out in the base image so it does not run while working on it
> during individual unit setup you will go in and uncomment the line

```sh
sudo su -
crontab -e
```

> use your favorite editor, i use vim.basic

Add the below lines to the crontab:
```sh
#
# Wireless-Monitor Utility
# (Uncomment to activate 5 minute monitor loop)
#
#*/5 * * * * /opt/wireless-monitor/bin/wireless-monitor

```




## Setup Contestnet

back on the live filesystem

> permissions got weird, everything got marked as executable

```sh
sudo chown -R kiosk:users /opt/contestnet
chmod +x /opt/contestnet/bin/launcher
chmod +x /opt/contestnet/bin/worker
chmod -x /opt/contestnet/etc/*
chmod g+w /opt/contestnet/etc/*
chmod -x /opt/contestnet/lib/Logger.pm
```


## Set the kiosk user to start contestnet on login

Add the following to `/home/kiosk/.bashrc`:

```sh
### ---------- Start Contestnet Terminal Application ---------- ###
#xinit /opt/contestnet/bin/launcher
#exit
### ----------------------------------------------------------- ###
```

> The launcher is left disabled in the base image for future maintenance
> once cloned for use, the comments will be removed



## Capture Image

```sh
sudo dd bs=4M if=/dev/sdb status=progress | xz > cn-master-001.img.xz
```

> real image is now cn-master-003.img.xz
