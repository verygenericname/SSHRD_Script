#!/usr/bin/env sh
# {

# $(rm *.log 2> /dev/null)
set -e
oscheck=$(uname)

version="$1"

major=$(echo "$version" | awk -F. '{print $1}')
minor=$(echo "$version" | awk -F. '{print $2}')
patch=$(echo "$version" | awk -F. '{print $3}')
major=${major:-0}
minor=${minor:-0}
patch=${patch:-0}
    
ERR_HANDLER () {
    [ $? -eq 0 ] && exit
    echo "[-] An error occurred"
    rm -rf work 12rd

   # echo "[-] Uploading logs. If this fails, it's not a big deal."
   # for file in *.log; do
   #     mv "$file" FAILURE_${file}
   # done
   # $(curl -A SSHRD_Script -F "fileToUpload=@$(ls *.log)" http://nathan4s.lol/SSHRD_Script/log_upload.php > /dev/null)
   # echo "[!] Done uploading logs, i'll be sure to look at them and fix the issue you are facing"
}

trap ERR_HANDLER EXIT

if [ ! -e sshtars/README.md ]; then
    git submodule update --init --recursive
fi

if [ -e sshtars/ssh.tar.gz ]; then
    if [ "$oscheck" = 'Linux' ]; then
        gzip -d sshtars/ssh.tar.gz
        gzip -d sshtars/t2ssh.tar.gz
        gzip -d sshtars/atvssh.tar.gz
    fi
fi


chmod +x "$oscheck"/*

if [ "$1" = 'clean' ]; then
    rm -rf sshramdisk work
    echo "[*] Removed the current created SSH ramdisk"
    exit
elif [ "$1" = 'dump-blobs' ]; then
    "$oscheck"/iproxy 2222 22 &>/dev/null &
    version=$("$oscheck"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost "sw_vers -productVersion")
    version=${version%%.*}
    if [ "$version" -ge 16 ]; then
        device=rdisk2
    else
        device=rdisk1
    fi
    "$oscheck"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost "cat /dev/$device" | dd of=dump.raw bs=256 count=$((0x4000))
    "$oscheck"/img4tool --convert -s dumped.shsh dump.raw
    killall iproxy
    echo "[*] Onboard blobs should have dumped to the dumped.shsh file"
    exit
elif [ "$1" = 'reset' ]; then
    "$oscheck"/iproxy 2222 22 &>/dev/null &
    "$oscheck"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost "nvram oblit-inprogress=5"
    "$oscheck"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost "sync"
    "$oscheck"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost "reboot"
    killall iproxy
    echo "[*] Device should now show a progress bar and erase all data"
    exit
elif [ "$1" = 'reboot' ]; then
    "$oscheck"/iproxy 2222 22 &>/dev/null &
    "$oscheck"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost "/sbin/reboot"
    echo "[*] Device should now reboot"
    exit
elif [ "$1" = 'ssh' ]; then
    "$oscheck"/iproxy 2222 22 &>/dev/null &
    "$oscheck"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost
    killall iproxy
    exit
elif [ "$oscheck" = 'Darwin' ]; then
    if ! (system_profiler SPUSBDataType 2> /dev/null | grep ' Apple Mobile Device (DFU Mode)' >> /dev/null); then
        echo "[*] Waiting for device in DFU mode"
    fi
    
    while ! (system_profiler SPUSBDataType 2> /dev/null | grep ' Apple Mobile Device (DFU Mode)' >> /dev/null); do
        sleep 1
    done
else
    if ! (lsusb 2> /dev/null | grep ' Apple, Inc. Mobile Device (DFU Mode)' >> /dev/null); then
        echo "[*] Waiting for device in DFU mode"
    fi
    
    while ! (lsusb 2> /dev/null | grep ' Apple, Inc. Mobile Device (DFU Mode)' >> /dev/null); do
        sleep 1
    done
fi

echo "[*] Getting device info and pwning... this may take a second"
check=$("$oscheck"/irecovery -q | grep CPID | sed 's/CPID: //')
replace=$("$oscheck"/irecovery -q | grep MODEL | sed 's/MODEL: //')
deviceid=$("$oscheck"/irecovery -q | grep PRODUCT | sed 's/PRODUCT: //')
ipswurl="$(curl -sL "https://api.ipsw.me/v4/device/$deviceid?type=ipsw" | "$oscheck"/jq '.firmwares | .[] | select(.version=="'$1'")' | "$oscheck"/jq -s '.[0] | .url' --raw-output)"

if [ -e work ]; then
    rm -rf work
fi

if [ -e 12rd ]; then
    rm -rf 12rd
fi

if [ ! -e sshramdisk ]; then
    mkdir sshramdisk
fi



if [ "$2" = 'TrollStore' ]; then
    if [ -z "$3" ]; then
        echo "[-] Please pass an uninstallable system app to use (Tips is a great choice)"
        exit
    fi
fi

if [ "$1" = 'boot' ]; then
    
    if [ ! -e "$oscheck"/palera1n ]; then
    curl -sLO https://nightly.link/verygenericname/palera1n/workflows/build/sshrd/palera1n-macosx-$(uname -m).zip
    unzip palera1n-macosx-$(uname -m).zip
    mv palera1n-macosx-$(uname -m) "$oscheck"/palera1n
    rm -rf palera1n-macosx-$(uname -m) palera1n-macosx-$(uname -m).zip
    chmod +x "$oscheck"/palera1n
fi

    "$oscheck"/palera1n -r sshramdisk/ramdisk.dmg

    echo "[*] Device should now show text on screen"
    exit
fi

if [ -z "$1" ]; then
    printf "1st argument: iOS version for the ramdisk\nExtra arguments:\nreset: wipes the device, without losing version.\nTrollStore: install trollstore to system app\n"
    exit
fi

if [ ! -e work ]; then
    mkdir work
fi


cd work
../"$oscheck"/pzb -g BuildManifest.plist "$ipswurl"


if [ "$oscheck" = 'Darwin' ]; then
    ../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl"
else
    ../"$oscheck"/pzb -g "$(../Linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')" "$ipswurl"
fi

cd ..
if [ "$oscheck" = 'Darwin' ]; then
    "$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" -o work/ramdisk.dmg
else
    "$oscheck"/img4 -i work/"$(Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')" -o work/ramdisk.dmg
fi

if [ "$oscheck" = 'Darwin' ]; then
    if [ "$major" -gt 16 ] || ([ "$major" -eq 16 ] && ([ "$minor" -gt 1 ] || [ "$minor" -eq 1 ] && [ "$patch" -ge 0 ])); then
    :
    else
        hdiutil resize -size 210MB work/ramdisk.dmg
    fi
    hdiutil attach -mountpoint /tmp/SSHRD work/ramdisk.dmg
    
    if [ "$major" -gt 16 ] || ([ "$major" -eq 16 ] && ([ "$minor" -gt 1 ] || [ "$minor" -eq 1 ] && [ "$patch" -ge 0 ])); then
        hdiutil create -size 210m -imagekey diskimage-class=CRawDiskImage -format UDZO -fs HFS+ -layout NONE -srcfolder /tmp/SSHRD -copyuid root work/ramdisk1.dmg
        hdiutil detach -force /tmp/SSHRD
        hdiutil attach -mountpoint /tmp/SSHRD work/ramdisk1.dmg
    else
    :
    fi
    
    if [ "$replace" = 'j42dap' ]; then
        "$oscheck"/gtar -x --no-overwrite-dir -f sshtars/atvssh.tar.gz -C /tmp/SSHRD/
    elif [ "$check" = '0x8012' ]; then
        "$oscheck"/gtar -x --no-overwrite-dir -f sshtars/t2ssh.tar.gz -C /tmp/SSHRD/
        echo "[!] WARNING: T2 MIGHT HANG AND DO NOTHING WHEN BOOTING THE RAMDISK!"
    else
    if [ "$major" -lt 11 ] || ([ "$major" -eq 11 ] && ([ "$minor" -lt 4 ] || [ "$minor" -eq 4 ] && [ "$patch" -le 1 ])); then
        mkdir 12rd
        ipswurl12=$(curl -sL "https://api.ipsw.me/v4/device/$deviceid?type=ipsw" | "$oscheck"/jq '.firmwares | .[] | select(.version=="'12.0'")' | "$oscheck"/jq -s '.[0] | .url' --raw-output)
        cd 12rd
        ../"$oscheck"/pzb -g BuildManifest.plist "$ipswurl12"
        ../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl12"
                ../"$oscheck"/img4 -i "$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" -o ramdisk.dmg
        hdiutil attach -mountpoint /tmp/12rd ramdisk.dmg
        cp /tmp/12rd/usr/lib/libiconv.2.dylib /tmp/12rd/usr/lib/libcharset.1.dylib /tmp/SSHRD/usr/lib/
        hdiutil detach -force /tmp/12rd
        cd ..
        rm -rf 12rd
    else
        :
            fi
        "$oscheck"/gtar -x --no-overwrite-dir -f sshtars/ssh.tar.gz -C /tmp/SSHRD/
    fi

    hdiutil detach -force /tmp/SSHRD
    if [ "$major" -gt 16 ] || ([ "$major" -eq 16 ] && ([ "$minor" -gt 1 ] || [ "$minor" -eq 1 ] && [ "$patch" -ge 0 ])); then
        hdiutil resize -sectors min work/ramdisk1.dmg
    else
        hdiutil resize -sectors min work/ramdisk.dmg
    fi
else
    if [ "$major" -gt 16 ] || ([ "$major" -eq 16 ] && ([ "$minor" -gt 1 ] || [ "$minor" -eq 1 ] && [ "$patch" -ge 0 ])); then
        echo "Sorry, 16.1 and above doesn't work on Linux at the moment!"
        exit
        else
        :
        fi
    "$oscheck"/hfsplus work/ramdisk.dmg grow 210000000 > /dev/null

    if [ "$replace" = 'j42dap' ]; then
        "$oscheck"/hfsplus work/ramdisk.dmg untar sshtars/atvssh.tar > /dev/null
    elif [ "$check" = '0x8012' ]; then
        "$oscheck"/hfsplus work/ramdisk.dmg untar sshtars/t2ssh.tar > /dev/null
        echo "[!] WARNING: T2 MIGHT HANG AND DO NOTHING WHEN BOOTING THE RAMDISK!"
    else
    if [ "$major" -lt 11 ] || ([ "$major" -eq 11 ] && ([ "$minor" -lt 4 ] || [ "$minor" -eq 4 ] && [ "$patch" -le 1 ])); then
        mkdir 12rd
        ipswurl12=$(curl -sL "https://api.ipsw.me/v4/device/$deviceid?type=ipsw" | "$oscheck"/jq '.firmwares | .[] | select(.version=="'12.0'")' | "$oscheck"/jq -s '.[0] | .url' --raw-output)
        cd 12rd
        ../"$oscheck"/pzb -g BuildManifest.plist "$ipswurl12"
        ../"$oscheck"/pzb -g "$(../Linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')" "$ipswurl12"
        ../"$oscheck"/img4 -i "$(../Linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')" -o ramdisk.dmg
        ../"$oscheck"/hfsplus ramdisk.dmg extract usr/lib/libcharset.1.dylib libcharset.1.dylib
        ../"$oscheck"/hfsplus ramdisk.dmg extract usr/lib/libiconv.2.dylib libiconv.2.dylib
        ../"$oscheck"/hfsplus ../work/ramdisk.dmg add libiconv.2.dylib usr/lib/libiconv.2.dylib
        ../"$oscheck"/hfsplus ../work/ramdisk.dmg add libcharset.1.dylib usr/lib/libcharset.1.dylib
        cd ..
        rm -rf 12rd
    else
    :
        fi
        "$oscheck"/hfsplus work/ramdisk.dmg untar sshtars/ssh.tar > /dev/null
    fi
fi
if [ "$oscheck" = 'Darwin' ]; then
if [ "$major" -gt 16 ] || ([ "$major" -eq 16 ] && ([ "$minor" -gt 1 ] || [ "$minor" -eq 1 ] && [ "$patch" -ge 0 ])); then
mv work/ramdisk1.dmg sshramdisk/ramdisk.dmg
else
mv work/ramdisk.dmg sshramdisk/ramdisk.dmg
fi
else
mv work/ramdisk.dmg sshramdisk/ramdisk.dmg
fi
echo ""
echo "[*] Cleaning up work directory"
rm -rf work 12rd

# echo "[*] Uploading logs. If this fails, your ramdisk is still created."
# set +e
# for file in *.log; do
#    mv "$file" SUCCESS_${file}
# done
# $(curl -A SSHRD_Script -F "fileToUpload=@$(ls *.log)" http://nathan4s.lol/SSHRD_Script/log_upload.php > /dev/null)
# set -e
# echo "[*] Done uploading logs!"

echo ""
echo "[*] Finished! Please use ./sshrd.sh boot to boot your device"
echo $1 > sshramdisk/version.txt

# } | tee "$(date +%T)"-"$(date +%F)"-"$(uname)"-"$(uname -r)".log
