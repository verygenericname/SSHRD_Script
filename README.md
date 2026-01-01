# SSH Ramdisk Script

<p align="center">
  <img src="https://img.shields.io/github/stars/kagbontaen/SSHRD_Script?style=for-the-badge" />
  <img src="https://img.shields.io/github/forks/kagbontaen/SSHRD_Script?style=for-the-badge" />
  <img src="https://img.shields.io/github/issues/kagbontaen/SSHRD_Script?style=for-the-badge" />
  <img src="https://img.shields.io/github/license/kagbontaen/SSHRD_Script?style=for-the-badge" />
</p>


<p align="center">
  <a href="https://github.com/kagbontaen/SSHRD_Script/graphs/contributors" target="_blank">
    <img src="https://img.shields.io/github/contributors/kagbontaen/SSHRD_Script.svg" alt="Contributors">
  </a>
  <a href="https://github.com/kagbontaen/SSHRD_Script/commits/main" target="_blank">
    <img src="https://img.shields.io/github/commit-activity/w/kagbontaen/SSHRD_Script.svg" alt="Commits">
  </a>
</p>

<p align="center">Create and boot a SSH ramdisk on checkm8 devices</p>

---

# About this Fork
This fork differs from **verygenericname's** version in the following ways:
- **Supports offline IPSW files** for ramdisk creation.
- **Automatically saves a copy of generated ramdisk files** to:
  ```
  ramdisk/<model>_<version>/
  ```

---

# Prerequisites
1. A computer running macOS or Linux
2. A checkm8-compatible device (A7–A11)

# Usage
1. Clone and enter the repository:
   ```bash
   git clone https://github.com/kagbontaen/SSHRD_Script --recursive && cd SSHRD_Script
   ```
   If previously cloned:
   ```bash
   cd SSHRD_Script && git pull
   ```

2. Run the ramdisk creation command:
   ```bash
   ./sshrd.sh <iOS version>
   ```
   - The iOS version does **not** need to match the device, but SEP must be compatible.
   - **Linux users:** iOS 16.1+ ramdisks cannot be created due to APFS changes; use 16.0 or lower.

3. Place your device into DFU mode.
   - A11 devices: Recovery Mode → DFU.

4. Boot the SSH ramdisk:
   ```bash
   ./sshrd.sh boot
   ```

5. Connect via SSH:
   ```bash
   ./sshrd.sh ssh
   ```

6. Mount filesystems:
   ```bash
   mount_filesystems
   ```
   - `/var` mounts to `/mnt2`
   - `/private/preboot` mounts to `/mnt6`
   - **Do NOT run this on very old iOS versions.**

# Linux Notes
On Linux, `usbmuxd` must be restarted. Run these in another terminal:
```bash
sudo systemctl stop usbmuxd
sudo usbmuxd -p -f
```

# Other Commands
- Reboot device: `./sshrd.sh reboot`
- Erase all data: `./sshrd.sh reset`
- Dump onboard SHSH blobs: `./sshrd.sh dump-blobs`
- Delete old ramdisk: `./sshrd.sh clean`

---

# Other Resources
- [Reddit Post](https://www.reddit.com/r/jailbreak/comments/wgiye1/free_release_ssh_ramdisk_creator_for_iphones_ipad/)

---

# Credits
- **remote-zip-viewer.py** (from the [remote-zip-downloader](https://github.com/kagbontaen/remote-zip-downloader) project)
- [tihmstar](https://github.com/tihmstar) — pzb, original iBoot64Patcher, img4tool
- [xerub](https://github.com/xerub) — img4lib, restored_external
- [Cryptic](https://github.com/Cryptiiiic) — iBoot64Patcher fork
- [opa334](https://github.com/opa334) — TrollStore
- [Nebula](https://github.com/itsnebulalol) — QOL fixes
- [OpenAI](https://chat.openai.com/chat) — kerneldiff → C port
- [Ploosh](https://github.com/plooshi) — KPlooshFinder
