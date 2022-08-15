#!/usr/bin/env bash

oscheck=$(uname)

if [[ -e sshramdisk ]]; then
 :
else
mkdir sshramdisk
fi

if [[ "$1" == 'reset' ]]; then

if [[ -e sshramdisk/iBSS.img4 ]] && [[ -e sshramdisk/iBEC.img4 ]]; then
    :
else
echo "please make a ssh ramdisk first!"
exit
fi

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

if [[ -e sshramdisk/iBSS.img4 ]] && [[ -e sshramdisk/iBEC.img4 ]]; then
    :
else
echo "please make a ssh ramdisk first!"
exit
fi

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

if [[ -e sshramdisk/iBSS.img4 ]] && [[ -e sshramdisk/iBEC.img4 ]]; then
    :
else
echo "please make a ssh ramdisk first!"
exit
fi

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

set -e

if [[ -e $oscheck/gaster ]]; then
    :
else
    curl -LO https://nightly.link/verygenericname/gaster/workflows/makefile/main/gaster-$oscheck.zip
    unzip gaster-$oscheck.zip
    mv gaster $oscheck/
    rm -rf gaster gaster-$oscheck.zip
fi

if [[ -e work ]]; then
 :
else
mkdir work
fi

trap "rm -rf work" INT ERR

chmod +x $oscheck/*
$oscheck/gaster pwn
$oscheck/img4tool -e -s $3 -m work/IM4M
cd work
../$oscheck/pzb -g BuildManifest.plist $1
if [[ "$4" == "" ]]; then
    ../$oscheck/pzb -g Firmware/dfu/iBSS.$2.RELEASE.im4p $1
    ../$oscheck/pzb -g Firmware/dfu/iBEC.$2.RELEASE.im4p $1
else
../$oscheck/pzb -g Firmware/dfu/iBSS.$4.RELEASE.im4p $1
../$oscheck/pzb -g Firmware/dfu/iBEC.$4.RELEASE.im4p $1
fi
../$oscheck/pzb -g Firmware/all_flash/DeviceTree.$2ap.im4p $1
if [[ "$oscheck" == 'Darwin' ]]; then
../$oscheck/pzb -g Firmware/$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1).trustcache $1
else
../$oscheck/pzb -g Firmware/$(../Linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g').trustcache $1
fi
if [[ "$2" == "n66m" ]]; then
../$oscheck/pzb -g kernelcache.release.n66 $1
elif [[ "$2" == "n71m" ]]; then
../$oscheck/pzb -g kernelcache.release.n71 $1
elif [[ "$2" == "n69" ]] || [[ "$2" == "n69u" ]]; then
../$oscheck/pzb -g kernelcache.release.iphone8b $1
elif [[ "$2" == "d10" ]] || [[ "$2" == "d11" ]]; then
../$oscheck/pzb -g kernelcache.release.iphone9 $1
elif [[ "$2" == "d22" ]]; then
../$oscheck/pzb -g kernelcache.release.iphone10b $1
elif [[ "$2" == "d20" ]] || [[ "$2" == "d21" ]]; then
../$oscheck/pzb -gkernelcache.release.iphone10 $1
elif [[ "$2" == "n61" ]] || [[ "$2" == "n56" ]]; then
../$oscheck/pzb -g kernelcache.release.iphone7 $1
elif [[ "$4" == "" ]]; then
../$oscheck/pzb -g kernelcache.release.$2 $1
else
../$oscheck/pzb -g kernelcache.release.$4 $1
fi
if [[ "$oscheck" == 'Darwin' ]]; then
../$oscheck/pzb -g $(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) $1
else
../$oscheck/pzb -g $(../Linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g') $1
fi
cd ..
if [[ "$4" == "" ]]; then
    $oscheck/gaster decrypt work/iBSS.$2.RELEASE.im4p work/iBSS.dec
    $oscheck/gaster decrypt work/iBEC.$2.RELEASE.im4p work/iBEC.dec
else
    $oscheck/gaster decrypt work/iBSS.$4.RELEASE.im4p work/iBSS.dec
    $oscheck/gaster decrypt work/iBEC.$4.RELEASE.im4p work/iBEC.dec
fi
$oscheck/iBoot64Patcher work/iBSS.dec work/iBSS.patched
$oscheck/img4 -i work/iBSS.patched -o sshramdisk/iBSS.img4 -M work/IM4M -A -T ibss
$oscheck/iBoot64Patcher work/iBEC.dec work/iBEC.patched -n -b "rd=md0 -v wdt=-9999999"
$oscheck/img4 -i work/iBEC.patched -o sshramdisk/iBEC.img4 -M work/IM4M -A -T ibec
if [[ "$2" == "n66m" ]]; then
$oscheck/img4 -i work/kernelcache.release.n66 -o work/kcache.raw
elif [[ "$2" == "n71m" ]]; then
$oscheck/img4 -i work/kernelcache.release.n71 -o work/kcache.raw
elif [[ "$2" == "n69" ]] || [[ "$2" == "n69u" ]]; then
$oscheck/img4 -i work/kernelcache.release.iphone8b -o work/kcache.raw
elif [[ "$2" == "d10" ]] || [[ "$2" == "d11" ]]; then
$oscheck/img4 -i work/kernelcache.release.iphone9 -o work/kcache.raw
elif [[ "$2" == "d22" ]]; then
$oscheck/img4 -i work/kernelcache.release.iphone10b -o work/kcache.raw
elif [[ "$2" == "d20" ]] || [[ "$2" == "d21" ]]; then
$oscheck/img4 -i work/kernelcache.release.iphone10 -o work/kcache.raw
elif [[ "$2" == "n61" ]] || [[ "$2" == "n56" ]]; then
$oscheck/img4 -i work/kernelcache.release.iphone7 -o work/kcache.raw
elif [[ "$4" == "" ]]; then
$oscheck/img4 -i work/kernelcache.release.$2 -o work/kcache.raw
else
$oscheck/img4 -i work/kernelcache.release.$4 -o work/kcache.raw
fi
$oscheck/Kernel64Patcher work/kcache.raw work/kcache.patched -a
python3 kerneldiff.py work/kcache.raw work/kcache.patched work/kc.bpatch
if [[ "$2" == "n66m" ]]; then
$oscheck/img4 -i work/kernelcache.release.n66 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch `if [[ "$oscheck" == 'Linux' ]]; then echo "-J"; fi`
elif [[ "$2" == "n71m" ]]; then
$oscheck/img4 -i work/kernelcache.release.n71 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch `if [[ "$oscheck" == 'Linux' ]]; then echo "-J"; fi`
elif [[ "$2" == "n69" ]] || [[ "$2" == "n69u" ]]; then
$oscheck/img4 -i work/kernelcache.release.iphone8b -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch `if [[ "$oscheck" == 'Linux' ]]; then echo "-J"; fi`
elif [[ "$2" == "d10" ]] || [[ "$2" == "d11" ]]; then
$oscheck/img4 -i work/kernelcache.release.iphone9 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch `if [[ "$oscheck" == 'Linux' ]]; then echo "-J"; fi`
elif [[ "$2" == "d22" ]]; then
$oscheck/img4 -i work/kernelcache.release.iphone10b -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch `if [[ "$oscheck" == 'Linux' ]]; then echo "-J"; fi`
elif [[ "$2" == "d20" ]] || [[ "$2" == "d21" ]]; then
$oscheck/img4 -i work/kernelcache.release.iphone10 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch `if [[ "$oscheck" == 'Linux' ]]; then echo "-J"; fi`
elif [[ "$2" == "n61" ]] || [[ "$2" == "n56" ]]; then
$oscheck/img4 -i work/kernelcache.release.iphone7 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch `if [[ "$oscheck" == 'Linux' ]]; then echo "-J"; fi`
elif [[ "$4" == "" ]]; then
$oscheck/img4 -i work/kernelcache.release.$2 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch `if [[ "$oscheck" == 'Linux' ]]; then echo "-J"; fi`
else
$oscheck/img4 -i work/kernelcache.release.$4 -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch `if [[ "$oscheck" == 'Linux' ]]; then echo "-J"; fi`
fi
$oscheck/img4 -i work/DeviceTree.$2ap.im4p -o sshramdisk/devicetree.img4 -M work/IM4M -T rdtr
if [[ "$oscheck" == 'Darwin' ]]; then
$oscheck/img4 -i work/$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1).trustcache -o sshramdisk/trustcache.img4 -M work/IM4M -T rtsc
$oscheck/img4 -i work/$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1) -o work/ramdisk.dmg
else
$oscheck/img4 -i work/$(Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g').trustcache -o sshramdisk/trustcache.img4 -M work/IM4M -T rtsc
$oscheck/img4 -i work/$(Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g') -o work/ramdisk.dmg
fi
if [[ "$oscheck" == 'Darwin' ]]; then
hdiutil resize -size 150MB work/ramdisk.dmg
hdiutil attach -mountpoint /tmp/SSHRD work/ramdisk.dmg
$oscheck/gtar -x --no-overwrite-dir -f ssh.tar -C /tmp/SSHRD/
hdiutil detach -force /tmp/SSHRD
hdiutil resize -sectors min work/ramdisk.dmg
else
mkdir sshrdtardir
tar -xf ssh.tar -C sshrdtardir/
$oscheck/hfsplus work/ramdisk.dmg addall sshrdtardir/ > /dev/null
rm -rf sshrdtardir
fi
$oscheck/img4 -i work/ramdisk.dmg -o sshramdisk/ramdisk.img4 -M work/IM4M -A -T rdsk
echo "we are done, please use ./sshrd.sh boot to boot your device"
echo cleanup...
rm -rf work
