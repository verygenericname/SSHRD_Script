#!/usr/bin/env sh

set -e

oscheck=$(uname)

ERR_HANDLER () {
    [ $? -eq 0 ] && exit
    echo "failed"
    rm -rf work
}

trap ERR_HANDLER EXIT

if [ -e "$oscheck"/gaster ]; then
    :
else
    curl -LO https://nightly.link/verygenericname/gaster/workflows/makefile/main/gaster-"$oscheck".zip
    unzip gaster-"$oscheck".zip
    mv gaster "$oscheck"/
    rm -rf gaster gaster-"$oscheck".zip
fi

chmod +x "$oscheck"/*

if [ "$oscheck" = 'Darwin' ]; then
while ! (system_profiler SPUSBDataType 2> /dev/null | grep " Apple Mobile Device" >> /dev/null); do
     echo "waiting for dfu mode"
     sleep 1
done
else
while ! (lsusb 2> /dev/null | grep " Apple, Inc. Mobile Device" >> /dev/null); do
    echo "waiting for dfu mode"
    sleep 1
done
fi 
check=$("$oscheck"/irecovery -q | grep CPID | sed 's/CPID: //')
replace=$("$oscheck"/irecovery -q | grep MODEL | sed 's/MODEL: //' | tr '[:upper:]' '[:lower:]' | sed 's/ap//g')

if [ -e work ]; then
 rm -rf work
else
 :
fi

if [ -e sshramdisk ]; then
 :
else
mkdir sshramdisk
fi

if [ "$1" = 'reset' ]; then

if [ -e sshramdisk/iBSS.img4 ] && [ -e sshramdisk/iBEC.img4 ]; then
    :
else
echo "please make a ssh ramdisk first!"
exit
fi

"$oscheck"/gaster pwn > /dev/null
"$oscheck"/gaster reset > /dev/null
"$oscheck"/irecovery -f sshramdisk/iBSS.img4
sleep 2
"$oscheck"/irecovery -f sshramdisk/iBEC.img4
if [ "$check" = '0x8010' ] || [ "$check" = '0x8015' ] || [ "$check" = '0x8011' ] || [ "$check" = '0x8012' ]; then
"$oscheck"/irecovery -c go
fi
sleep 2
"$oscheck"/irecovery -c "setenv oblit-inprogress 5"
"$oscheck"/irecovery -c saveenv
"$oscheck"/irecovery -c reset
echo "device should now show a progress bar when booting and then go to setup screen"
exit
fi

if [ "$1" = 'set-nonce' ]; then

if [ -z "$2" ]; then
echo "2nd argument: generator here"
exit 1
fi

if [ -e sshramdisk/iBSS.img4 ] && [ -e sshramdisk/iBEC.img4 ]; then
    :
else
echo "please make a ssh ramdisk first!"
exit
fi

"$oscheck"/gaster pwn > /dev/null
"$oscheck"/gaster reset > /dev/null
"$oscheck"/irecovery -f sshramdisk/iBSS.img4
sleep 2
"$oscheck"/irecovery -f sshramdisk/iBEC.img4
if [ "$check" = '0x8010' ] || [ "$check" = '0x8015' ] || [ "$check" = '0x8011' ] || [ "$check" = '0x8012' ]; then
"$oscheck"/irecovery -c go
fi
sleep 2
"$oscheck"/irecovery -c "setenv com.apple.System.boot-nonce $2"
"$oscheck"/irecovery -c saveenv
"$oscheck"/irecovery -c reset
echo "nonce set to $2 successfully"
exit
fi

if [ "$1" = 'boot' ]; then

if [ -e sshramdisk/iBSS.img4 ] && [ -e sshramdisk/iBEC.img4 ]; then
    :
else
echo "please make a ssh ramdisk first!"
exit 1
fi

"$oscheck"/gaster pwn > /dev/null
"$oscheck"/gaster reset > /dev/null
"$oscheck"/irecovery -f sshramdisk/iBSS.img4
sleep 2
"$oscheck"/irecovery -f sshramdisk/iBEC.img4
if [ "$check" = '0x8010' ] || [ "$check" = '0x8015' ] || [ "$check" = '0x8011' ] || [ "$check" = '0x8012' ]; then
"$oscheck"/irecovery -c go
fi
sleep 2
"$oscheck"/irecovery -f sshramdisk/ramdisk.img4
"$oscheck"/irecovery -c ramdisk
"$oscheck"/irecovery -f sshramdisk/devicetree.img4
"$oscheck"/irecovery -c devicetree
"$oscheck"/irecovery -f sshramdisk/trustcache.img4
"$oscheck"/irecovery -c firmware
"$oscheck"/irecovery -f sshramdisk/kernelcache.img4
"$oscheck"/irecovery -c bootx
echo "device should show text on screen now."
exit
fi

if [ -z "$1" ]; then
    printf "1st argument: IPSW Link\n2nd argument(OPTIONAL): SHSH Blob\nExtra arguments:\nreset: wipes the device, without losing version.\nset-nonce: sets the nonce to the generator you specify.\n"
    exit
fi

if [ -e work ]; then
 :
else
mkdir work
fi

"$oscheck"/gaster pwn
if [ "$2" = "" ]; then
"$oscheck"/img4tool -e -s shsh/"${check}".shsh -m work/IM4M
else
"$oscheck"/img4tool -e -s "$2" -m work/IM4M
fi
cd work
../"$oscheck"/pzb -g BuildManifest.plist "$1"
../"$oscheck"/pzb -g "$(awk "/"${replace}"/{x=1}x&&/iBSS[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$1"
../"$oscheck"/pzb -g "$(awk "/"${replace}"/{x=1}x&&/iBEC[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$1"
../"$oscheck"/pzb -g "$(awk "/"${replace}"/{x=1}x&&/DeviceTree[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$1"
if [ "$oscheck" = 'Darwin' ]; then
../"$oscheck"/pzb -g Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache "$1"
else
../"$oscheck"/pzb -g Firmware/"$(../Linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')".trustcache "$1"
fi
../"$oscheck"/pzb -g "$(awk "/"${replace}"/{x=1}x&&/kernelcache.release/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$1"
if [ "$oscheck" = 'Darwin' ]; then
../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$1"
else
../"$oscheck"/pzb -g "$(../Linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')" "$1"
fi
cd ..
"$oscheck"/gaster decrypt work/"$(awk "/"${replace}"/{x=1}x&&/iBSS[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]dfu[/]//')" work/iBSS.dec
"$oscheck"/gaster decrypt work/"$(awk "/"${replace}"/{x=1}x&&/iBEC[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]dfu[/]//')" work/iBEC.dec
"$oscheck"/iBoot64Patcher work/iBSS.dec work/iBSS.patched -n #was missing arg "-n" to unlock nvram shit
"$oscheck"/img4 -i work/iBSS.patched -o sshramdisk/iBSS.img4 -M work/IM4M -A -T ibss
"$oscheck"/iBoot64Patcher work/iBEC.dec work/iBEC.patched -n -b "rd=md0 debug=0x2014e -v wdt=-9999999"
"$oscheck"/img4 -i work/iBEC.patched -o sshramdisk/iBEC.img4 -M work/IM4M -A -T ibec
"$oscheck"/img4 -i work/"$(awk "/"${replace}"/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" -o work/kcache.raw
"$oscheck"/Kernel64Patcher work/kcache.raw work/kcache.patched -a
python3 kerneldiff.py work/kcache.raw work/kcache.patched work/kc.bpatch
"$oscheck"/img4 -i work/"$(awk "/"${replace}"/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" -o sshramdisk/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch `if [ "$oscheck" = 'Linux' ]; then echo "-J"; fi`
"$oscheck"/img4 -i work/"$(awk "/"${replace}"/{x=1}x&&/DeviceTree[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//')" -o sshramdisk/devicetree.img4 -M work/IM4M -T rdtr
if [ "$oscheck" = 'Darwin' ]; then
"$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache -o sshramdisk/trustcache.img4 -M work/IM4M -T rtsc
"$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" -o work/ramdisk.dmg
else
"$oscheck"/img4 -i work/"$(Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')".trustcache -o sshramdisk/trustcache.img4 -M work/IM4M -T rtsc
"$oscheck"/img4 -i work/"$(Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')" -o work/ramdisk.dmg
fi
if [ "$oscheck" = 'Darwin' ]; then
hdiutil resize -size 150MB work/ramdisk.dmg
hdiutil attach -mountpoint /tmp/SSHRD work/ramdisk.dmg
if [ "$replace" = 'j42d' ]; then
"$oscheck"/gtar -x --no-overwrite-dir -f sshtars/atvssh.tar -C /tmp/SSHRD/
elif [ "$check" = '0x8012' ]; then
"$oscheck"/gtar -x --no-overwrite-dir -f sshtars/t2ssh.tar -C /tmp/SSHRD/
else
"$oscheck"/gtar -x --no-overwrite-dir -f sshtars/ssh.tar -C /tmp/SSHRD/
fi
hdiutil detach -force /tmp/SSHRD
hdiutil resize -sectors min work/ramdisk.dmg
else
"$oscheck"/hfsplus work/ramdisk.dmg grow 150000000 > /dev/null
if [ "$replace" = 'j42d' ]; then
"$oscheck"/hfsplus work/ramdisk.dmg untar sshtars/atvssh.tar > /dev/null
elif [ "$check" = '0x8012' ]; then
"$oscheck"/hfsplus work/ramdisk.dmg untar sshtars/t2ssh.tar > /dev/null
else
"$oscheck"/hfsplus work/ramdisk.dmg untar sshtars/ssh.tar > /dev/null
fi
fi
"$oscheck"/img4 -i work/ramdisk.dmg -o sshramdisk/ramdisk.img4 -M work/IM4M -A -T rdsk
echo "we are done, please use ./sshrd.sh boot to boot your device"
echo "cleanup..."
rm -rf work
