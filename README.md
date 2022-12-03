<h1 align="center">SSH Ramdisk Script</h1>
<p align="center">
  <a href="https://github.com/verygenericname/SSHRD_Script/graphs/contributors" target="_blank">
    <img src="https://img.shields.io/github/contributors/verygenericname/SSHRD_Script.svg" alt="Contributors">
  </a>
  <a href="https://github.com/verygenericname/SSHRD_Script/commits/main" target="_blank">
    <img src="https://img.shields.io/github/commit-activity/w/verygenericname/SSHRD_Script.svg" alt="Commits">
  </a>
</p>

<p align="center">
Create and boot a SSH ramdisk on checkm8 devices
</p>

---

# Prerequsites

1. A computer running macOS/linux
2. A checkm8 device (A7-A11) NOTE: iPhone 6 and below cannot have filesystems mounted for unknown reasons.

# Usage

1. Clone and cd into this repository: `git clone https://github.com/verygenericname/SSHRD_Script --recursive && cd SSHRD_Script`
    - If you have cloned this before, run `cd SSHRD_Script && git pull` to pull new changes
2. Run `./sshrd.sh <iOS version for ramdisk>`, **without** the `<>`.
    - The iOS version doesn't have to be the version you're currently on, but it should be close enough, and SEP has to be compatible
    - If you're on Linux, you will not be able to make a ramdisk for 16.1+, please use something lower instead, like 16.0
        - This is due to ramdisks switching to APFS over HFS+, and another dmg library would have to be used
3. Place your device into DFU mode
    - A11 users, go to recovery first, then DFU.
4. Run `./sshrd.sh boot` to boot the ramdisk
5. Run `./sshrd.sh ssh` to connect to SSH on your device
6. Finally, to mount the filesystems, run `mount_filesystems`  
    - /var is mounted to /mnt2 in the ssh session.
    - /private/preboot is mounted to /mnt6.
    - DO NOT RUN THIS IF THE DEVICE IS ON A REALLY OLD VERSION!!!!!!!
7. Have fun!

# Linux notes

On Linux, usbmuxd will have to be restarted. On most distros, it's as simple as these 2 commands in another terminal:
```
sudo systemctl stop usbmuxd
sudo usbmuxd -p -f
```

# Other commands

- Reboot your device: `./sshrd.sh reboot`
- Erase all data from your device: `./sshrd.sh reset`
- Dump onboard SHSH blobs: `./sshrd.sh dump-blobs`
- Delete old SSH ramdisk: `./sshrd.sh clean`

# Other Stuff

- [Reddit Post](https://www.reddit.com/r/jailbreak/comments/wgiye1/free_release_ssh_ramdisk_creator_for_iphones_ipad/)

# Credits

- [tihmstar](https://github.com/tihmstar) for pzb/original iBoot64Patcher/img4tool
- [xerub](https://github.com/xerub) for img4lib and restored_external in the ramdisk
- [Cryptic](https://github.com/Cryptiiiic) for iBoot64Patcher fork
- [opa334](https://github.com/opa334) for TrollStore
- [Nebula](https://github.com/itsnebulalol) for a bunch of QOL fixes to this script
- [OpenAI](https://chat.openai.com/chat) for converting [kerneldiff](https://github.com/mcg29/kerneldiff) into [C](https://github.com/verygenericname/kerneldiff_C)
