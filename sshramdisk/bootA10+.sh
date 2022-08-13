#!/usr/bin/env bash
if [[ "$1" == 'reset' ]]; then
irecovery -f iBSS.img4
set -e
irecovery -f iBSS.img4
sleep 2
irecovery -f iBEC.img4
irecovery -c go
sleep 4
irecovery -c "setenv oblit-inprogress 5"
irecovery -c saveenv
irecovery -c reset
echo "device should now show a progress bar when booting and then go to setup screen"
exit
fi

if [[ "$1" == 'set-nonce' ]]; then
: ${2?"2nd argument: generator here"}

irecovery -f iBSS.img4
set -e
irecovery -f iBSS.img4
sleep 2
irecovery -f iBEC.img4
irecovery -c go
sleep 4
irecovery -c "setenv com.apple.System.boot-nonce $2"
irecovery -c saveenv
irecovery -c reset  
echo "nonce set to $2 successfully"
exit
fi

irecovery -f iBSS.img4
irecovery -f iBSS.img4
sleep 2
irecovery -f iBEC.img4
irecovery -c go
sleep 4
irecovery -f ramdisk.img4
irecovery -c ramdisk
irecovery -f devicetree.img4
irecovery -c devicetree
irecovery -f trustcache.img4
irecovery -c firmware
irecovery -f kernelcache.img4
irecovery -c bootx
echo "device should show text on screen now."
