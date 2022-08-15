#!/usr/bin/env bash

if [[ -e sshramdisk ]]; then
 :
else
mkdir sshramdisk
fi

if [[ "$1" == 'reset' ]]; then
check=$(irecovery -q | grep CPID | sed 's/CPID: //')

irecovery -f sshramdisk/iBSS.img4
set -e
irecovery -f sshramdisk/iBSS.img4
sleep 2
irecovery -f sshramdisk/iBEC.img4
if [[ "$check" == '0x8010' ]] || [[ "$check" == '0x8015' ]] || [[ "$check" == '0x8011' ]]; then
irecovery -c go
fi
sleep 2
irecovery -c "setenv oblit-inprogress 5"
irecovery -c saveenv
irecovery -c reset
echo "device should now show a progress bar when booting and then go to setup screen"
exit
fi

if [[ "$1" == 'set-nonce' ]]; then
: ${2?"2rd argument: generator here"}
check=$(irecovery -q | grep CPID | sed 's/CPID: //')

irecovery -f sshramdisk/iBSS.img4
set -e
irecovery -f sshramdisk/iBSS.img4
sleep 2
irecovery -f sshramdisk/iBEC.img4
if [[ "$check" == '0x8010' ]] || [[ "$check" == '0x8015' ]] || [[ "$check" == '0x8011' ]]; then
irecovery -c go
fi
sleep 2
irecovery -c "setenv com.apple.System.boot-nonce $2"
irecovery -c saveenv
irecovery -c reset
echo "nonce set to $2 successfully"
exit
fi

if [[ "$1" == 'boot' ]]; then
check=$(irecovery -q | grep CPID | sed 's/CPID: //')

irecovery -f sshramdisk/iBSS.img4
set -e
irecovery -f sshramdisk/iBSS.img4
sleep 2
irecovery -f sshramdisk/iBEC.img4
if [[ "$check" == '0x8010' ]] || [[ "$check" == '0x8015' ]] || [[ "$check" == '0x8011' ]]; then
irecovery -c go
fi
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

: ${1?"1st argument: ipsw link"}
: ${2?"2nd argument: board cfg (no AP part, lowercase)"}
: ${3?"3rd argument: can be any shsh blob, just make sure it's from the same ecid as your phone"}

if [[ "$(uname)" == 'Darwin' ]]; then

set -e

if [[ -e macos/gaster ]]; then
    :
else
    curl -LO https://nightly.link/verygenericname/gaster/workflows/makefile/main/gaster-mac.zip
    unzip gaster-mac.zip
    mv gaster macos/
    rm -rf gaster gaster-mac.zip
fi

if [[ -e work ]]; then
 :
else
mkdir work
fi

trap "rm -rf work" INT ERR

chmod +x macos/*
macos/gaster pwn
macos/img4tool -e -s $3 -m work/IM4M
cd work
../macos/pzb -g BuildManifest.plist $1
if [[ "$4" == "" ]]; then
    ../macos/pzb -g Firmware/dfu/iBSS.$2.RELEASE.im4p $1
    ../macos/pzb -g Firmware/dfu/iBEC.$2.RELEASE.im4p $1
else
../macos/pzb -g Firmware/dfu/iBSS.$4.RELEASE.im4p $1
../macos/pzb -g Firmware/dfu/iBEC.$4.RELEASE.im4p $1
fi
../macos/pzb -g Firmware/all_flash/DeviceTree.$2ap.im4p $1
../macos/pzb -g Firmware/$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1).trustcache $1
if [[ "$2" == "n66m" ]]; then
../macos/pzb -g kernelcache.release.n66 $1
elif [[ "$2" == "n71m" ]]; then
../macos/pzb -g kernelcache.release.n71 $1
elif [[ "$2" == "n69" ]] || [[ "$2" == "n69u" ]]; then
../macos/pzb -g kernelcache.release.iphone8b $1
elif [[ "$2" == "d10" ]] || [[ "$2" == "d11" ]]; then
../macos/pzb -g kernelcache.release.iphone9 $1
elif [[ "$2" == "d22" ]]; then
../macos/pzb -g kernelcache.release.iphone10b $1
elif [[ "$2" == "d20" ]] || [[ "$2" == "d21" ]]; then
../macos/pzb -gkernelcache.release.iphone10 $1
elif [[ "$2" == "n61" ]] || [[ "$2" == "n56" ]]; then
../macos/pzb -g kernelcache.release.iphone7 $1
elif [[ "$4" == "" ]]; then
../macos/pzb -g kernelcache.release.$2 $1
else
../macos/pzb -g kernelcache.release.$4 $1
fi
../macos/pzb -g $(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
cd ..
if [[ "$4" == "" ]]; then
    macos/gaster decrypt work/iBSS.$2.RELEASE.im4p work/iBSS.dec
    macos/gaster decrypt work/iBEC.$2.RELEASE.im4p work/iBEC.dec
else
    macos/gaster decrypt work/iBSS.$4.RELEASE.im4p work/iBSS.dec
    macos/gaster decrypt work/iBEC.$4.RELEASE.im4p work/iBEC.dec
fi
macos/iBoot64Patcher work/iBSS.dec work/iBSS.patched
macos/img4 -i work/iBSS.patched -o sshramdisk/iBSS.img4 -M work/IM4M -A -T ibss
macos/iBoot64Patcher work/iBEC.dec work/iBEC.patched -n -b "rd=md0 -v wdt=-9999999"
macos/img4 -i work/iBEC.patched -o sshramdisk/iBEC.img4 -M work/IM4M -A -T ibec
if [[ "$2" == "n66m" ]]; then
macos/img4 -i work/kernelcache.release.n66 -o work/kcache.raw
elif [[ "$2" == "n71m" ]]; then
macos/img4 -i work/kernelcache.release.n71 -o work/kcache.raw
elif [[ "$2" == "n69" ]] || [[ "$2" == "n69u" ]]; then
macos/img4 -i work/kernelcache.release.iphone8b -o work/kcache.raw
elif [[ "$2" == "d10" ]] || [[ "$2" == "d11" ]]; then
macos/img4 -i work/kernelcache.release.iphone9 -o work/kcache.raw
elif [[ "$2" == "d22" ]]; then
macos/img4 -i work/kernelcache.release.iphone10b -o work/kcache.raw
elif [[ "$2" == "d20" ]] || [[ "$2" == "d21" ]]; then
macos/img4 -i work/kernelcache.release.iphone10 -o work/kcache.raw
elif [[ "$2" == "n61" ]] || [[ "$2" == "n56" ]]; then
macos/img4 -i work/kernelcache.release.iphone7 -o work/kcache.raw
elif [[ "$4" == "" ]]; then
macos/img4 -i work/kernelcache.release.$2 -o work/kcache.raw
else
macos/img4 -i work/kernelcache.release.$4 -o work/kcache.raw
fi
macos/Kernel64Patcher work/kcache.raw work/kcache.patched -a
python3 kerneldiff.py work/kcache.raw work/kcache.patched work/kc.bpatch
if [[ "$2" == "n66m" ]]; then
macos/img4 -i work/kernelcache.release.n66 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch
elif [[ "$2" == "n71m" ]]; then
macos/img4 -i work/kernelcache.release.n71 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch
elif [[ "$2" == "n69" ]] || [[ "$2" == "n69u" ]]; then
macos/img4 -i work/kernelcache.release.iphone8b -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch
elif [[ "$2" == "d10" ]] || [[ "$2" == "d11" ]]; then
macos/img4 -i work/kernelcache.release.iphone9 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch
elif [[ "$2" == "d22" ]]; then
macos/img4 -i work/kernelcache.release.iphone10b -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch
elif [[ "$2" == "d20" ]] || [[ "$2" == "d21" ]]; then
macos/img4 -i work/kernelcache.release.iphone10 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch
elif [[ "$2" == "n61" ]] || [[ "$2" == "n56" ]]; then
macos/img4 -i work/kernelcache.release.iphone7 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch
elif [[ "$4" == "" ]]; then
macos/img4 -i work/kernelcache.release.$2 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch
else
macos/img4 -i work/kernelcache.release.$4 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch
fi
macos/img4 -i work/DeviceTree.$2ap.im4p -o sshramdisk/devicetree.img4 -M work/IM4M -T rdtr
macos/img4 -i work/$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1).trustcache -o sshramdisk/trustcache.img4 -M work/IM4M -T rtsc
macos/img4 -i work/$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o work/ramdisk.dmg
hdiutil resize -size 150MB work/ramdisk.dmg
hdiutil attach -mountpoint /tmp/SSHRD work/ramdisk.dmg
macos/gtar -x --no-overwrite-dir -f ssh.tar -C /tmp/SSHRD/
hdiutil detach -force /tmp/SSHRD
hdiutil resize -sectors min work/ramdisk.dmg
macos/img4 -i work/ramdisk.dmg -o sshramdisk/ramdisk.img4 -M work/IM4M -A -T rdsk
echo "we are done, please use ./sshrd.sh boot to boot your device"
echo cleanup...
rm -rf work


elif [[ "$(uname)" == 'Linux' ]]; then

set -e

if [[ -e linux/gaster ]]; then
    :
else
    curl -LO https://nightly.link/verygenericname/gaster/workflows/makefile/main/gaster-linux.zip
    unzip gaster-linux.zip
    mv gaster linux/
    rm -rf gaster gaster-linux.zip
fi

if [[ -e work ]]; then
 :
else
mkdir work
fi

trap "rm -rf work" INT ERR

chmod +x linux/*
linux/gaster pwn
linux/img4tool -e -s $3 -m work/IM4M
cd work
../linux/pzb -g BuildManifest.plist $1
if [[ "$4" == "" ]]; then
    ../linux/pzb -g Firmware/dfu/iBSS.$2.RELEASE.im4p $1
    ../linux/pzb -g Firmware/dfu/iBEC.$2.RELEASE.im4p $1
else
../linux/pzb -g Firmware/dfu/iBSS.$4.RELEASE.im4p $1
../linux/pzb -g Firmware/dfu/iBEC.$4.RELEASE.im4p $1
fi
../linux/pzb -g Firmware/all_flash/DeviceTree.$2ap.im4p $1
../linux/pzb -g Firmware/$(../linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g').trustcache $1
if [[ "$2" == "n66m" ]]; then
../linux/pzb -g kernelcache.release.n66 $1
elif [[ "$2" == "n71m" ]]; then
../linux/pzb -g kernelcache.release.n71 $1
elif [[ "$2" == "n69" ]] || [[ "$2" == "n69u" ]]; then
../linux/pzb -g kernelcache.release.iphone8b $1
elif [[ "$2" == "d10" ]] || [[ "$2" == "d11" ]]; then
../linux/pzb -g kernelcache.release.iphone9 $1
elif [[ "$2" == "d22" ]]; then
../linux/pzb -g kernelcache.release.iphone10b $1
elif [[ "$2" == "d20" ]] || [[ "$2" == "d21" ]]; then
../linux/pzb -g kernelcache.release.iphone10 $1
elif [[ "$2" == "n61" ]] || [[ "$2" == "n56" ]]; then
../linux/pzb -g kernelcache.release.iphone7 $1
elif [[ "$4" == "" ]]; then
../linux/pzb -g kernelcache.release.$2 $1
else
../linux/pzb -g kernelcache.release.$4 $1
fi
../linux/pzb -g $(../linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g') $1
cd ..
if [[ "$4" == "" ]]; then
    linux/gaster decrypt work/iBSS.$2.RELEASE.im4p work/iBSS.dec
    linux/gaster decrypt work/iBEC.$2.RELEASE.im4p work/iBEC.dec
else
    linux/gaster decrypt work/iBSS.$4.RELEASE.im4p work/iBSS.dec
    linux/gaster decrypt work/iBEC.$4.RELEASE.im4p work/iBEC.dec
fi
linux/iBoot64Patcher work/iBSS.dec work/iBSS.patched
linux/img4 -i work/iBSS.patched -o sshramdisk/iBSS.img4 -M work/IM4M -A -T ibss
linux/iBoot64Patcher work/iBEC.dec work/iBEC.patched -n -b "rd=md0 -v wdt=-9999999"
linux/img4 -i work/iBEC.patched -o sshramdisk/iBEC.img4 -M work/IM4M -A -T ibec
if [[ "$2" == "n66m" ]]; then
linux/img4 -i work/kernelcache.release.n66 -o work/kcache.raw
elif [[ "$2" == "n71m" ]]; then
linux/img4 -i work/kernelcache.release.n71 -o work/kcache.raw
elif [[ "$2" == "n69" ]] || [[ "$2" == "n69u" ]]; then
linux/img4 -i work/kernelcache.release.iphone8b -o work/kcache.raw
elif [[ "$2" == "d10" ]] || [[ "$2" == "d11" ]]; then
linux/img4 -i work/kernelcache.release.iphone9 -o work/kcache.raw
elif [[ "$2" == "d22" ]]; then
linux/img4 -i work/kernelcache.release.iphone10b -o work/kcache.raw
elif [[ "$2" == "d20" ]] || [[ "$2" == "d21" ]]; then
linux/img4 -i work/kernelcache.release.iphone10 -o work/kcache.raw
elif [[ "$2" == "n61" ]] || [[ "$2" == "n56" ]]; then
linux/img4 -i work/kernelcache.release.iphone7 -o work/kcache.raw
elif [[ "$4" == "" ]]; then
linux/img4 -i work/kernelcache.release.$2 -o work/kcache.raw
else
linux/img4 -i work/kernelcache.release.$4 -o work/kcache.raw
fi
linux/Kernel64Patcher work/kcache.raw work/kcache.patched -a
python3 kerneldiff.py work/kcache.raw work/kcache.patched work/kc.bpatch
if [[ "$2" == "n66m" ]]; then
linux/img4 -i work/kernelcache.release.n66 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch -J
elif [[ "$2" == "n71m" ]]; then
linux/img4 -i work/kernelcache.release.n71 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch -J
elif [[ "$2" == "n69" ]] || [[ "$2" == "n69u" ]]; then
linux/img4 -i work/kernelcache.release.iphone8b -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch -J
elif [[ "$2" == "d10" ]] || [[ "$2" == "d11" ]]; then
linux/img4 -i work/kernelcache.release.iphone9 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch -J
elif [[ "$2" == "d22" ]]; then
linux/img4 -i work/kernelcache.release.iphone10b -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch -J
elif [[ "$2" == "d20" ]] || [[ "$2" == "d21" ]]; then
linux/img4 -i work/kernelcache.release.iphone10 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch -J
elif [[ "$2" == "n61" ]] || [[ "$2" == "n56" ]]; then
linux/img4 -i work/kernelcache.release.iphone7 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch -J
elif [[ "$4" == "" ]]; then
linux/img4 -i work/kernelcache.release.$2 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch -J
else
linux/img4 -i work/kernelcache.release.$4 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch -J
fi
linux/img4 -i work/DeviceTree.$2ap.im4p -o sshramdisk/devicetree.img4 -M work/IM4M -T rdtr
linux/img4 -i work/$(linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g').trustcache -o sshramdisk/trustcache.img4 -M work/IM4M -T rtsc
linux/img4 -i work/$(linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g') -o work/ramdisk.dmg
mkdir sshrdtardir
tar -xf ssh.tar -C sshrdtardir/
linux/hfsplus work/ramdisk.dmg addall sshrdtardir/ > /dev/null
linux/img4 -i work/ramdisk.dmg -o sshramdisk/ramdisk.img4 -M work/IM4M -A -T rdsk
rm -rf sshrdtardir
echo "we are done, please use ./sshrd.sh boot to boot your device"
echo cleanup...
rm -rf work
fi
