irecovery -f ~/.zshrc
irecovery -f ~/.zshrc
irecovery -f iBSS.img4
sleep 2
irecovery -f iBSS.img4
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
