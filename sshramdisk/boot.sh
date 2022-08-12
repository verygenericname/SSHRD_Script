#!/bin/bash
if [[ "$1" == 'reset' ]]; then
irecovery -f iBSS.img4
irecovery -f iBSS.img4
sleep 2
irecovery -f iBEC.img4
sleep 2
irecovery -c "setenv oblit-inprogress 5"
irecovery -c saveenv
irecovery -c reset
fi

irecovery -f iBSS.img4
irecovery -f iBSS.img4
sleep 2
irecovery -f iBEC.img4
sleep 2
irecovery -f ramdisk.img4
irecovery -c ramdisk
irecovery -f devicetree.img4
irecovery -c devicetree
irecovery -f trustcache.img4
irecovery -c firmware
irecovery -f kernelcache.img4
irecovery -c bootx
