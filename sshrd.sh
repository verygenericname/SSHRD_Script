#!/bin/bash

chmod +x macos/*


: ${1?"1st argument: ipsw link"}
: ${2?"2nd argument: board cfg, can be iphone6 for example too (no AP part, lowercase)"}


macos/pzb -g BuildManifest.plist $1 1> /dev/null
macos/pzb -g Firmware/dfu/iBSS.$2.RELEASE.im4p $1
macos/pzb -g Firmware/dfu/iBEC.$2.RELEASE.im4p $1
