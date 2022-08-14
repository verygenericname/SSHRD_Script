#!/usr/bin/env bash

if [[ "$1" == 'boot' ]]; then
if [[ "$2" == 'reset' ]]; then
irecovery -f sshramdisk/iBSS.img4
set -e
irecovery -f sshramdisk/iBSS.img4
sleep 2
irecovery -f sshramdisk/iBEC.img4
sleep 2
irecovery -c "setenv oblit-inprogress 5"
irecovery -c saveenv
irecovery -c reset
echo "device should now show a progress bar when booting and then go to setup screen"
exit
fi

if [[ "$2" == 'set-nonce' ]]; then
: ${3?"3rd argument: generator here"}

irecovery -f sshramdisk/iBSS.img4
set -e
irecovery -f sshramdisk/iBSS.img4
sleep 2
irecovery -f sshramdisk/iBEC.img4
sleep 2
irecovery -c "setenv com.apple.System.boot-nonce $3"
irecovery -c saveenv
irecovery -c reset
echo "nonce set to $3 successfully"
exit
fi

irecovery -f sshramdisk/iBSS.img4
set -e
irecovery -f sshramdisk/iBSS.img4
sleep 2
irecovery -f sshramdisk/iBEC.img4
sleep 2
irecovery -f sshramdisk/ramdisk.img4
irecovery -c ramdisk
irecovery -f sshramdisk/devicetree.img4
irecovery -c devicetree
irecovery -f sshramdisk/trustcache.img4
irecovery -c firmware
irecovery -f sshramdisk/kernelcache.img4
irecovery -c bootx
echo "device should show text on screen now."
exit
fi

if [[ "$1" == 'bootA10+' ]]; then
if [[ "$2" == 'reset' ]]; then
irecovery -f sshramdisk/iBSS.img4
set -e
irecovery -f sshramdisk/iBSS.img4
sleep 2
irecovery -f sshramdisk/iBEC.img4
irecovery -c go
sleep 4
irecovery -c "setenv oblit-inprogress 5"
irecovery -c saveenv
irecovery -c reset
echo "device should now show a progress bar when booting and then go to setup screen"
exit
fi

if [[ "$2" == 'set-nonce' ]]; then
: ${3?"3rd argument: generator here"}

irecovery -f sshramdisk/iBSS.img4
set -e
irecovery -f sshramdisk/iBSS.img4
sleep 2
irecovery -f sshramdisk/iBEC.img4
irecovery -c go
sleep 4
irecovery -c "setenv com.apple.System.boot-nonce $3"
irecovery -c saveenv
irecovery -c reset
echo "nonce set to $3 successfully"
exit
fi

irecovery -f sshramdisk/iBSS.img4
set -e
irecovery -f sshramdisk/iBSS.img4
sleep 2
irecovery -f sshramdisk/iBEC.img4
irecovery -c go
sleep 4
irecovery -f sshramdisk/ramdisk.img4
irecovery -c ramdisk
irecovery -f sshramdisk/devicetree.img4
irecovery -c devicetree
irecovery -f sshramdisk/trustcache.img4
irecovery -c firmware
irecovery -f sshramdisk/kernelcache.img4
irecovery -c bootx
echo "device should show text on screen now."
exit
fi

: ${1?"1st argument: ipsw link"}
: ${2?"2nd argument: board cfg (no AP part, lowercase)"}
: ${3?"3rd argument: can be any shsh blob, just make sure it's from the same ecid as your phone"}

if [[ "$(uname)" == 'Darwin' ]]; then

set -e

if [[ -e macos/gaster ]]; then
    echo "gaster downloaded already."
else
    curl -LO https://nightly.link/verygenericname/gaster/workflows/makefile/main/gaster-mac.zip
    unzip gaster-mac.zip
    mv gaster macos/
    rm -rf gaster gaster-mac.zip
fi
chmod +x macos/*
macos/gaster pwn
macos/img4tool -e -s $3 -m IM4M
macos/pzb -g BuildManifest.plist $1
if [[ "$4" == "" ]]; then
    macos/pzb -g Firmware/dfu/iBSS.$2.RELEASE.im4p $1
    macos/pzb -g Firmware/dfu/iBEC.$2.RELEASE.im4p $1
else
macos/pzb -g Firmware/dfu/iBSS.$4.RELEASE.im4p $1
macos/pzb -g Firmware/dfu/iBEC.$4.RELEASE.im4p $1
fi
macos/pzb -g Firmware/all_flash/DeviceTree.$2ap.im4p $1
macos/pzb -g Firmware/$(/usr/libexec/PlistBuddy BuildManifest.plist -c "print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path").trustcache $1
if [[ "$2" == "n66m" ]]; then
macos/pzb -g $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.n66</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
elif [[ "$2" == "n71m" ]]; then
macos/pzb -g $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.n71</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
elif [[ "$2" == "n69" ]] || [[ "$2" == "n69u" ]]; then
macos/pzb -g $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone8b</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
elif [[ "$2" == "d10" ]] || [[ "$2" == "d11" ]]; then
macos/pzb -g $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone9</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
elif [[ "$2" == "d22" ]]; then
macos/pzb -g $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone10b</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
elif [[ "$2" == "d20" ]] || [[ "$2" == "d21" ]]; then
macos/pzb -g $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone10</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
elif [[ "$2" == "n61" ]] || [[ "$2" == "n56" ]]; then
macos/pzb -g $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone7</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
elif [[ "$4" == "" ]]; then
macos/pzb -g $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.$2</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
else
macos/pzb -g $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.$4</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
fi
macos/pzb -g $(/usr/libexec/PlistBuddy BuildManifest.plist -c "print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path") $1
if [[ "$4" == "" ]]; then
    macos/gaster decrypt iBSS.$2.RELEASE.im4p iBSS.dec
    macos/gaster decrypt iBEC.$2.RELEASE.im4p iBEC.dec
else
    macos/gaster decrypt iBSS.$4.RELEASE.im4p iBSS.dec
    macos/gaster decrypt iBEC.$4.RELEASE.im4p iBEC.dec
fi
macos/iBoot64Patcher iBSS.dec iBSS.patched
macos/img4 -i iBSS.patched -o iBSS.img4 -M IM4M -A -T ibss
macos/iBoot64Patcher iBEC.dec iBEC.patched -n -b "rd=md0 -v wdt=-9999999"
macos/img4 -i iBEC.patched -o iBEC.img4 -M IM4M -A -T ibec
if [[ "$2" == "n66m" ]]; then
macos/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.n66</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kcache.raw
elif [[ "$2" == "n71m" ]]; then
macos/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.n71</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kcache.raw
elif [[ "$2" == "n69" ]] || [[ "$2" == "n69u" ]]; then
macos/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone8b</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kcache.raw
elif [[ "$2" == "d10" ]] || [[ "$2" == "d11" ]]; then
macos/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone9</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kcache.raw
elif [[ "$2" == "d22" ]]; then
macos/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone10b</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kcache.raw
elif [[ "$2" == "d20" ]] || [[ "$2" == "d21" ]]; then
macos/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone10</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kcache.raw
elif [[ "$2" == "n61" ]] || [[ "$2" == "n56" ]]; then
macos/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone7</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kcache.raw
elif [[ "$4" == "" ]]; then
macos/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.$2</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kcache.raw
else
macos/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.$4</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kcache.raw
fi
macos/Kernel64Patcher kcache.raw kcache.patched -a
python3 kerneldiff.py kcache.raw kcache.patched
if [[ "$2" == "n66m" ]]; then
macos/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.n66</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch
elif [[ "$2" == "n71m" ]]; then
macos/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.n71</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch
elif [[ "$2" == "n69" ]] || [[ "$2" == "n69u" ]]; then
macos/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone8b</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch
elif [[ "$2" == "d10" ]] || [[ "$2" == "d11" ]]; then
macos/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone9</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch
elif [[ "$2" == "d22" ]]; then
macos/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone10b</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch
elif [[ "$2" == "d20" ]] || [[ "$2" == "d21" ]]; then
macos/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone10</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch
elif [[ "$2" == "n61" ]] || [[ "$2" == "n56" ]]; then
macos/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone7</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch
elif [[ "$4" == "" ]]; then
macos/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.$2</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch
else
macos/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.$4</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch
fi
macos/img4 -i DeviceTree.$2ap.im4p -o devicetree.img4 -M IM4M -T rdtr
macos/img4 -i $(/usr/libexec/PlistBuddy BuildManifest.plist -c "print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path").trustcache -o trustcache.img4 -M IM4M -T rtsc
macos/img4 -i $(/usr/libexec/PlistBuddy BuildManifest.plist -c "print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path") -o ramdisk.dmg
hdiutil resize -size 120MB ramdisk.dmg
hdiutil attach -mountpoint /tmp/SSHRD ramdisk.dmg
macos/gtar -x --no-overwrite-dir -f ssh.tar -C /tmp/SSHRD/
hdiutil detach -force /tmp/SSHRD
hdiutil resize -sectors min ramdisk.dmg
macos/img4 -i ramdisk.dmg -o ramdisk.img4 -M IM4M -A -T rdsk
mv ramdisk.img4 sshramdisk
mv trustcache.img4 sshramdisk
mv devicetree.img4 sshramdisk
mv kernelcache.img4 sshramdisk
mv iBEC.img4 sshramdisk
mv iBSS.img4 sshramdisk
echo "we are done, please use boot.sh (or bootA10+.sh for a10 above) to boot your device in the sshramdisk folder"
echo cleanup...
if [[ "$4" == "" ]]; then
    rm iBSS.$2.RELEASE.im4p
    rm iBEC.$2.RELEASE.im4p
else
    rm iBSS.$4.RELEASE.im4p
    rm iBEC.$4.RELEASE.im4p
fi
rm iBSS.dec
rm iBEC.dec
rm iBSS.patched
rm iBEC.patched
if [[ "$2" == "n66m" ]]; then
rm $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.n66</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
elif [[ "$2" == "n71m" ]]; then
rm $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.n71</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
elif [[ "$2" == "n69" ]] || [[ "$2" == "n69u" ]]; then
rm $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone8b</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
elif [[ "$2" == "d10" ]] || [[ "$2" == "d11" ]]; then
rm $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone9</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
elif [[ "$2" == "d22" ]]; then
rm $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone10b</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
elif [[ "$2" == "d20" ]] || [[ "$2" == "d21" ]]; then
rm $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone10</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
elif [[ "$2" == "n61" ]] || [[ "$2" == "n56" ]]; then
rm $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone7</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
elif [[ "$4" == "" ]]; then
rm $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.$2</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
else
rm $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.$4</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
fi
rm $(/usr/libexec/PlistBuddy BuildManifest.plist -c "print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path")
rm $(/usr/libexec/PlistBuddy BuildManifest.plist -c "print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path").trustcache
rm BuildManifest.plist
rm kcache.raw
rm kcache.patched
rm DeviceTree.$2ap.im4p
rm IM4M
rm kc.bpatch
touch kc.bpatch
rm ramdisk.dmg


elif [[ "$(uname)" == 'Linux' ]]; then

set -e

if [[ -e linux/gaster ]]; then
    echo "gaster downloaded already."
else
    curl -LO https://nightly.link/verygenericname/gaster/workflows/makefile/main/gaster-linux.zip
    unzip gaster-linux.zip
    mv gaster linux/
    rm -rf gaster gaster-linux.zip
fi
chmod +x linux/*
linux/gaster pwn
linux/img4tool -e -s $3 -m IM4M
linux/pzb -g BuildManifest.plist $1
if [[ "$4" == "" ]]; then
    linux/pzb -g Firmware/dfu/iBSS.$2.RELEASE.im4p $1
    linux/pzb -g Firmware/dfu/iBEC.$2.RELEASE.im4p $1
else
linux/pzb -g Firmware/dfu/iBSS.$4.RELEASE.im4p $1
linux/pzb -g Firmware/dfu/iBEC.$4.RELEASE.im4p $1
fi
linux/pzb -g Firmware/all_flash/DeviceTree.$2ap.im4p $1
linux/pzb -g Firmware/$(linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g').trustcache $1
if [[ "$2" == "n66m" ]]; then
linux/pzb -g $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.n66</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
elif [[ "$2" == "n71m" ]]; then
linux/pzb -g $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.n71</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
elif [[ "$2" == "n69" ]] || [[ "$2" == "n69u" ]]; then
linux/pzb -g $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone8b</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
elif [[ "$2" == "d10" ]] || [[ "$2" == "d11" ]]; then
linux/pzb -g $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone9</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
elif [[ "$2" == "d22" ]]; then
linux/pzb -g $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone10b</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
elif [[ "$2" == "d20" ]] || [[ "$2" == "d21" ]]; then
linux/pzb -g $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone10</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
elif [[ "$2" == "n61" ]] || [[ "$2" == "n56" ]]; then
linux/pzb -g $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone7</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
elif [[ "$4" == "" ]]; then
linux/pzb -g $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.$2</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
else
linux/pzb -g $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.$4</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
fi
linux/pzb -g $(linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g') $1
if [[ "$4" == "" ]]; then
    linux/gaster decrypt iBSS.$2.RELEASE.im4p iBSS.dec
    linux/gaster decrypt iBEC.$2.RELEASE.im4p iBEC.dec
else
    linux/gaster decrypt iBSS.$4.RELEASE.im4p iBSS.dec
    linux/gaster decrypt iBEC.$4.RELEASE.im4p iBEC.dec
fi
linux/iBoot64Patcher iBSS.dec iBSS.patched
linux/img4 -i iBSS.patched -o iBSS.img4 -M IM4M -A -T ibss
linux/iBoot64Patcher iBEC.dec iBEC.patched -n -b "rd=md0 -v wdt=-9999999"
linux/img4 -i iBEC.patched -o iBEC.img4 -M IM4M -A -T ibec
if [[ "$2" == "n66m" ]]; then
linux/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.n66</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kcache.raw
elif [[ "$2" == "n71m" ]]; then
linux/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.n71</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kcache.raw
elif [[ "$2" == "n69" ]] || [[ "$2" == "n69u" ]]; then
linux/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone8b</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kcache.raw
elif [[ "$2" == "d10" ]] || [[ "$2" == "d11" ]]; then
linux/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone9</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kcache.raw
elif [[ "$2" == "d22" ]]; then
linux/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone10b</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kcache.raw
elif [[ "$2" == "d20" ]] || [[ "$2" == "d21" ]]; then
linux/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone10</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kcache.raw
elif [[ "$2" == "n61" ]] || [[ "$2" == "n56" ]]; then
linux/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone7</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kcache.raw
elif [[ "$4" == "" ]]; then
linux/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.$2</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kcache.raw
else
linux/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.$4</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kcache.raw
fi
linux/Kernel64Patcher kcache.raw kcache.patched -a
python3 kerneldiff.py kcache.raw kcache.patched
if [[ "$2" == "n66m" ]]; then
linux/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.n66</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch -J
elif [[ "$2" == "n71m" ]]; then
linux/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.n71</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch -J
elif [[ "$2" == "n69" ]] || [[ "$2" == "n69u" ]]; then
linux/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone8b</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch -J
elif [[ "$2" == "d10" ]] || [[ "$2" == "d11" ]]; then
linux/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone9</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch -J
elif [[ "$2" == "d22" ]]; then
linux/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone10b</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch -J
elif [[ "$2" == "d20" ]] || [[ "$2" == "d21" ]]; then
linux/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone10</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch -J
elif [[ "$2" == "n61" ]] || [[ "$2" == "n56" ]]; then
linux/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone7</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch -J
elif [[ "$4" == "" ]]; then
linux/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.$2</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch -J
else
linux/img4 -i $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.$4</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch -J
fi
linux/img4 -i DeviceTree.$2ap.im4p -o devicetree.img4 -M IM4M -T rdtr
linux/img4 -i $(linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g').trustcache -o trustcache.img4 -M IM4M -T rtsc
linux/img4 -i $(linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g') -o ramdisk.dmg
mkdir sshrdtardir
tar -xf ssh.tar -C sshrdtardir/
linux/hfsplus ramdisk.dmg addall sshrdtardir/ > /dev/null
linux/img4 -i ramdisk.dmg -o ramdisk.img4 -M IM4M -A -T rdsk
rm -rf sshrdtardir
mv ramdisk.img4 sshramdisk
mv trustcache.img4 sshramdisk
mv devicetree.img4 sshramdisk
mv kernelcache.img4 sshramdisk
mv iBEC.img4 sshramdisk
mv iBSS.img4 sshramdisk
echo "we are done, please use boot.sh (or bootA10+.sh for a10 above) to boot your device in the sshramdisk folder"
echo cleanup...
if [[ "$4" == "" ]]; then
    rm iBSS.$2.RELEASE.im4p
    rm iBEC.$2.RELEASE.im4p
else
    rm iBSS.$4.RELEASE.im4p
    rm iBEC.$4.RELEASE.im4p
fi
rm iBSS.dec
rm iBEC.dec
rm iBSS.patched
rm iBEC.patched
if [[ "$2" == "n66m" ]]; then
rm $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.n66</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
elif [[ "$2" == "n71m" ]]; then
rm $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.n71</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
elif [[ "$2" == "n69" ]] || [[ "$2" == "n69u" ]]; then
rm $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone8b</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
elif [[ "$2" == "d10" ]] || [[ "$2" == "d11" ]]; then
rm $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone9</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
elif [[ "$2" == "d22" ]]; then
rm $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone10b</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
elif [[ "$2" == "d20" ]] || [[ "$2" == "d21" ]]; then
rm $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone10</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
elif [[ "$2" == "n61" ]] || [[ "$2" == "n56" ]]; then
rm $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.iphone7</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
elif [[ "$4" == "" ]]; then
rm $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.$2</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
else
rm $(cat BuildManifest.plist | grep -A2  "<string>kernelcache.release.$4</string>" | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
fi
rm $(linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')
rm $(linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g').trustcache
rm BuildManifest.plist
rm kcache.raw
rm kcache.patched
rm DeviceTree.$2ap.im4p
rm IM4M
rm kc.bpatch
touch kc.bpatch
rm ramdisk.dmg
fi
