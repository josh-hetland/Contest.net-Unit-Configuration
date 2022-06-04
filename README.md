# Contest.net Display Unit - Worker Process

The Contest.net Display Unit is a kiosk for displaying content such as pre-event sales advertisments, promotional videos, and during the event
the live leader board display to show overall standings and new entry placement details.

These units run in remote locations that are time consuming to reach, so emphasis is put on the reliability and remote control of the units.

This project is broken into three repositories
* [Configuration](https://github.com/josh-hetland/Contest.net-Unit-Configuration) _(this one)_
* [Launcher](https://github.com/josh-hetland/Contest.net-Unit-Launcher)
* [Worker](https://github.com/josh-hetland/Contest.net-Unit-Worker)

The configuration repository contains the documentation on setting up a vanilla OS image to act as a display unit
and any additional utilities or artifacts it uses.


The instructions are broken into two main parts

## Image Creation

This is the step by step process for taking a vanilla raspbian image and getting it ready to be a master image
that will be cloned for each unit.

These instructions change slightly over time as the raspbian images have changed so i am tracking them
in separate files for historical reference

* [Bullseye Image](./MASTER-IMAGE-BULLSEYE.md)
* [Jessie Image](./master-image.txt)


## Unit Setup

Each unit gets a copy of the base image, slightly taylored to it _(basically just enabling some of the services and setting its unit ID for checkin)_

Currently these steps are captured in [unit-configuration.txt](./unit-configuration.txt)

> I intend to convert this to mardown as well
