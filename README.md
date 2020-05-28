<a href="https://www.buymeacoffee.com/BinaryShrub" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a>

# Ubuntu on BTRFS with LUKS Disk Encryption
This guide walks you through setting up [Ubuntu 20.04 LTS](https://wiki.ubuntu.com/FocalFossa/ReleaseNotes) on [BTRFS](https://btrfs.wiki.kernel.org/index.php/Main_Page) using [GPT](https://en.wikipedia.org/wiki/GUID_Partition_Table) , [UEFI](https://en.wikipedia.org/wiki/Unified_Extensible_Firmware_Interface), [LUKS](https://gitlab.com/cryptsetup/cryptsetup/blob/master/README.md) Disk Encryption, and [dropbear-initramfs](https://packages.ubuntu.com/focal/net/dropbear-initramfs) ssh client to unlock the root partition from the bootloader remotely!

> [![](assets/partitions.svg)](https://app.diagrams.net/?lightbox=1&highlight=0000ff&edit=_blank&layers=1&nav=1&title=Untitled%20Diagram.drawio#R5Zhdb5swFIZ%2FDZeRAAMjlyVN1krrJoVKu3bAAWsGM8dpyH79jsF8JVRt1CRd10SK7PfYx%2BZ9bAwx0CwrvwpcpA88Jsywzbg00K1h257nwq8S9lpAXi0kgsa1ZHVCSP8QLZpa3dKYbAYNJedM0mIoRjzPSSQHGhaC74bN1pwNRy1wQo6EMMLsWP1JY5nWqu%2BanX5HaJI2I1umjmS4aayFTYpjvutJaG6gmeBc1qWsnBGmvGt8qfstnom2ExMkl6%2FpUFL8Yxl%2Fm9DvD%2FcWYssUPbkTy6%2FTPGG21VesZyv3jQWCb%2FOYqCymgYJdSiUJCxyp6A6Yg5bKjEHNguKa51JTtE1dn3HGRZUL1R%2FQMaNJDloEsydCNaSM9RquXfUFfSMF%2F0V6Ea%2F6QETPnAhJymc9sVqnYYUSnhEp9tCk6dDA0avT8nV917F2mqWY9jhPtYb18kra1B0BKGgIJwBxRnh4DEYNVlBIZHXdtaCsHZDyfm95E5hsKgg30MDyi7ILNlnmi%2FsmEUy0zjXMD3JvzDctiiHb2CV%2B7Iyx9e0VOhtbdMB2eszWH0H75VJox7baRdAqcOq28l%2FjtQ%2B37nvjnV4R73uhXfsRiaIxtCvfdVzzPGiR9TJae%2ByufDG2zWA9uMHjchGCyThTluWrTTFmNpggh442B5%2Bopx0opyg8b9xoPaNxrHoHgsBCwKsqkzK24DSX1YW5geHeqlRbyevF0h69FzonHe9lIt4IEPtiQKzPDcR2%2FjUg9hGQxc0jsj8LEOsVO8S9KpDRJ8kBi3keiX0h4SyAWcxtYzozfPcEQIysPwyfwzOl3UA9PtOr8vGO%2BITh3Qnut29OH8L%2Fw8e1Mf%2Bd8%2FgP1e6tuor1%2FppA878%3D)

## Operation: Get Ubuntu Installed on BTRFS with LUKS
By the end of this section you should have a bare bones Ubuntu system up and running on BTRFS with LUKS. It will be a little rough around the edges (like manually running commands locally to get past LUKS and boot) but it's a start!

<p align="center"><img src="assets/letsdothis.png"/></p>

> This guide was written through the lense of `macOS` and may need to be tailored accordingly for other operating systems like `Linux` or `Windows` – contributions are welcome!

### Download Ubuntu 20.04 LTS

1. Download Ubuntu 20.04 LTS image:</br>[https://releases.ubuntu.com/20.04/ubuntu-20.04-desktop-amd64.iso](https://releases.ubuntu.com/20.04/ubuntu-20.04-desktop-amd64.iso)

### [optional] Setup VirtualBox
I'd recommend before doing anything on 'real' hardware, that you follow along on a VM for quicker iteration and learning without breaking your own 💩.

The rest of the guide should pertain to either path you decide on.

<details><summary>CLICK HERE to Setup VM with VirtualBox</summary>
<p>

#### Setup VirtualBox
1. Download and install [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
    ```
    brew cask install virtualbox
    ```
#### Create a new VM
1. Launch VirtualBox, click `New`</br></br>**Type:** `Linux`</br>**Version:** `Ubuntu (64-bit)`</br>
![](assets/vb-new.png)
1. Continue with defaults (which should include a **10 GB** virtual drive)

#### Configure and Launch new VM
1. Select VM from step above and click `Settings`
2. Navigate to **System > Motherboard** 
3. Check `Enable EFI (special OSes only)`</br>
![](assets/vb-mobo.png)
4. Navigate to **Storage**
5. Attach `ubuntu-20.04-desktop-amd64.iso` as a new Optical Drive
![](assets/vb-storage.png)
1. [optional] Increase VM performance 
   > I put my numbers below but do what suites you
   
   **Base Memory:** `2048 MB`</br>**Processor(s)** `4`</br>**Video Memory:** `128 MB`
2. Click `OK` to save settings
3. Click `Start`
4.  [optional] Change VM to Scaled Mode (View > Scaled Mode) for a better viewing experience
5.  You should be off to the races 🏇</br>
![](assets/vb-launch.png)

---

</p>
</details>

### Launch 'Try Ubuntu' from Installer USB/CD
1. If you are not going the VirtualBox VM route you will need to [build an Ubuntu Live USB](https://ubuntu.com/tutorials/tutorial-create-a-usb-stick-on-ubuntu) from `ubuntu-20.04-desktop-amd64.iso` and launch into it.
2. Start your system, boot to the attached Ubuntu environment, and select `Try Ubuntu` once fully loaded.
3. Open `terminal` (Ctrl+Opt+T on macOS) and run `lsblk` to list out your block devices and locate the drive you will be installing Ubuntu on – in my case `sda`</br>
![](assets/vb-lsblk.png)
4. Jot down your disk name if it's different than mine (`sda`) and use it for the remainder of this guide
5. Launch interactive sudo `sudo -i` in terminal – it's time to get our hands dirty 🙌

### Create Disk Partitions
1. Launch `parted` in interactive sudo to setup a `GPT` partition table and create our three partitions: `EFI`, `/boot`, `/`</br>
    ```
    parted /dev/sda
        mklabel gpt
        mkpart primary 1MiB 513MiB
        mkpart primary 513MiB 1026MiB
        mkpart primary 1026MiB 100%
        print
        quit
    ```

    ![](assets/parted.png)

### Setup LUKS Disk Encryption on `/` partition
1. Setup encryption on `/` partition:
    ```
    cryptsetup luksFormat /dev/sda3
    ```
    > **Use a strong passphrase**: This passphrase is what will be used to unlock your disk encryption in the future – avoid brute force attacks and use something long and strong 😘.
    
    > If you on on VirtualBox, you may get a `Killed` response with a screen flicker, this means luksFormat failed. Try with `--pbkdf-memory 256` to reduce the required memory – not recommended if you can avoid it. 
2. Open your newly created LUKS `/` partition:
   ```
   cryptsetup luksOpen /dev/sda3 sda3_crypt
   ```
   > This will mount an LVM at `/dev/mapper/sda3_crypt` which is affectively your decrypted partition.

### Format Disk Partitions
1. Format `EFI` partition:
    ```
    mkfs.vfat -F 32 /dev/sda1
    ```
2. Format `/boot` partition:
    ```
    mkfs.btrfs /dev/sda2
    ```
1. Format `/` partition:
    ```
    mkfs.btrfs /dev/mapper/sda3_crypt
    ```
    > You do not want to use /dev/sda3 here because it's encrypted.

### Install Ubuntu 👨‍💻
1. Launch Ubuntu Installer from interactive sudo terminal
   ```
   ubiquity
   ```
   ![](assets/installer.png)
2. Continue with your desired settings until you hit the **Installation type** page, here you want to select the `Something else` radial button
![](assets/installtype.png)
3. We are now going to tell the Ubuntu installer how/where we want our installation:
   1. Select `/dev/sda1`, press the Change button. Choose Use as `EFI System Partition`.</br>
        > If this is not an option, you probably didn't boot with UEFI Support in VirtualBox or your System doesnt support UEFI 🙁
   1. Select `/dev/sda2`, press the Change button. Choose Use as ‘btrfs journaling filesystem’, check `Format`, and use ‘/boot’ as Mount point.
   2. Select `/dev/mapper/sda3_crypt`, press the Change button. Choose Use as ‘btrfs journaling filesystem’, check `Format`, and use ‘/’ as Mount point.
![](assets/installtypeparts.png)
4. Click `Install Now`
5. Continue through the rest of the installation with your desired settings
![](assets/installcomplete.png)
6. Remove the Ubuntu Installer USB/CD – it is no longer needed.
7. Click `Restart Now`
8. Congrats, Ubuntu is installed on BTRFS with LUKS 🎉 – time for a test drive to see if it works 🚙...

### Launch your new Ubuntu System for the First Time
1. Once booted/restarted you should end up in `initramfs` running `BusyBox`. This is because your `/boot` volume could not understand what it should be doing since it cannot find the `/` partition – it doesn't know it's encrypted:
![](assets/initramfs.png)
2. Perform the manual boot steps to launch Ubuntu
   1. open the encrypted `/` partition
       ```
       cryptsetup luksOpen /dev/sda3 sda3_crypt
       ```
   2. Scan for the `/` partition filesystem
       ```
       btrfs device scan
       ```
   3. Exit to continue the booting process
       ```
       exit
       ```
![](assets/manualboot.png)
3. If all's good, you should be loaded to Ubuntu!
![](assets/booted.png)
4. [optional] If you are on VirtualBox, you should now install `VirtualBox Guest Additions` to make your experience better

---

## Operation: Make Things Better with Unlock Script and Bootloader SSH Client

COMING SOON!

> See [btrfs-luks-unlocker.sh](https://github.com/BinaryShrub/ubuntu-btrfs-luks/blob/master/scripts/btrfs-luks-unlocker.sh) for a sneak peak... it's what's for dinner 🍔.