# PXE SERVER LINUX WINDOWS 10 /2019 UEFI BIOS

[Contribution guidelines for this project](docs/pxelinwinueficontri)

I have asked to setup the Linux PXE server with windows 10 / 2019 bootable clients with UEFI BIOS. since im not  WIN SA, i have created this one stop ref doc for implementing UEFI based BIOs windows boot from Linux PXE server. After spending several days on research about UEFI + Linux PXE Server + windows pxe boot. I hope this will help SA community if come accros with commbination.

I'm going over only for UEFI BIOS Based systems. I have used iPXE to cover the above requirment for many features. You can get more info about [this](http://ipxe.org). My special thanks to this team.

### Environment :
I used cent OS 7 as PXE, DHCP, TFTP, HTTP, SAMABA server.
Client machines :  vmware or physical machines running with UEFI based system.

## Prerequieste for linux server ( PXE Server)

I have skipped the Installation  procedure for  Linux server and static ip configuarations for linux server.


``` [root@centos]# yum install  xinetd tftp-server  dhcp syslinux samba samba-common samba-winbind httpd vsftpd -y```

Note: vsftpd and httpd used for file transfer while network installation either in linux or windows systems.

Let configure the required services from the above package installations.

### > Tftp-server Services :
configure tftp server

$#chmod -R 755 /var/lib/tftpboot

vi  /etc/xinet.d/tftp and modify "disable = no" from yes
```
service tftp
{
        socket_type             = dgram
        protocol                = udp
        wait                    = yes
        user                    = root
        server                  = /usr/sbin/in.tftpd
        server_args             = -s /var/lib/tftpboot
        disable                 = no               <<<<<<<<<<<<< modify
        per_source              = 11
        cps                     = 100 2
        flags                   = IPv4
}
Start the  services
$ systemctl enable xinetd
$ systemctl start xinetd
$ systemctl status xinetd
```
### > Dhcp Services :
Configure the dhcp server as below. 

```
$ mv /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.org
$ vi /etc/dhcp/dhcpd.conf

allow booting;
allow bootp;
default-lease-time 600;
max-lease-time 7200;

log-facility local7;

option space pxelinux;
option pxelinux.magic code 208 = string;
option pxelinux.configfile code 209 = text;
option pxelinux.pathprefix code 210 = text;
option pxelinux.reboottime code 211 = unsigned integer 32;
option architecture-type code 93 = unsigned integer 16;


subnet 192.168.23.0 netmask 255.255.255.0 {
  range 192.168.23.51 192.168.23.60;
  option subnet-mask 255.255.255.0;
  option routers 192.168.23.130, 192.168.23.2;

        class "pxeclients" {
          match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
          next-server 192.168.23.130;

        if exists user-class and option user-class = "iPXE" {
            filename "boot.ipxe";
        } else if option architecture-type = 00:06 {
            filename "uefi/bootia32.efi";
        } else if option architecture-type = 00:07 or option architecture-type = 00:09 {
            filename "ipxe.efi";
		} else  if option architecture-type!= 00:00 {
            filename "pxelinux.cfg/grubx64.efi";
            #filename "http:/192.168.23.130/winboot/pxelinux.0";
        } else {
            filename "pxelinux.0";

          }
        }

}

Start the services 
$ systemctl enable dhcpd
$ systemctl start dhcpd
$ systemctl status dhcpd

```

### > Syslinux Bootloaders: 

>Copy files from  syslinux directory to tftpboot directory

```#cp -r /usr/share/syslinux/* /var/lib/tftpboot/```

### > Samba Server Services :

```
[root@centos]# cat /etc/samba/smb.conf
[global]
        workgroup = PXESERVER
        server string = Samba Server Version %v
        log file = /var/log/samba/log.%m
        max log size = 50
        idmap config * : backend = tdb
        cups options = raw
        netbios name = pxe
        map to guest = bad user
        dns proxy = no
        public = yes
        ## For multiple installations the same time - not lock kernel
        kernel oplocks = no
        nt acl support = no
        security = user
        guest account = nobody

[wininstall]
        comment = Windows Images
        path = /var/www/html/windows
        read only = no
        browseable = yes
        public = yes
        printable = no
        guest ok = yes
        oplocks = no
        level2 oplocks = no
        locking = no
        writeable = yes
		
[lininstall]
        comment = Linux Images
        path = /var/www/html/linux
        read only = no
        browseable = yes
        public = yes
        printable = no
        guest ok = yes
        oplocks = no
        level2 oplocks = no
        locking = no
        writeable = yes
```
*Now check your config file os ok or not*

``` 
$ testparm
Load smb config files from /etc/samba/smb.conf
rlimit_max: increasing rlimit_max (1024) to minimum Windows limit (16384)
Processing section "[install]"
Loaded services file OK.
Server role: ROLE_STANDALONE

Press enter to see a dump of your service definitions
```
***Once done enable and start the related services***
```
$ systemctl enable smb
$ systemctl enable winbind
$ systemctl enable nmb

$ systemctl start smb
$ systemctl start winbind
$ systemctl start nmb
```
**_Check your status by bellow command_**

```
$ systemctl status smb || nmb || winbind
```

### > iPXE Network ROM:

##### Now lets create IPXE config files.
```
mkdir /var/www/html/windows/boot
$ cd /var/www/html/windows/boot
wget http://git.ipxe.org/releases/wimboot/wimboot-latest.zip

### Unzip this file on same location and rename to wimboot

### Get the ipxe.efi  and place it to /var/lib/tftpd.
$ cd /var/lib/tftpboot/
wget http://boot.ipxe.org/ipxe.efi

### now create boot.ipxe file
$ vi boot.ipxe

#!ipxe
kernel http://192.168.23.130/windows/boot/wimboot
initrd http://192.168.23.130/windows/boot/bcd         BCD
initrd http://192.168.23.130/windows/boot/boot.sdi    boot.sdi
initrd http://192.168.23.130/windows/boot/boot.wim    boot.wim
boot

```

#### Copy Source install files to the location
*Mount your windows10 ISO Image*
```
$ mkdir -p /var/www/html/windows/2019
$ mount /dev/cdrom /mnt
$ cp -rf /mnt/* /var/www/html/windows/2019/
```
*Unmount and mount linux OS (centos7) ISO image*
```
$ mkdir -p /var/www/html/linux/rhel7
$ mount /dev/cdrom /mnt
$ cp -rf /mnt/* /var/www/html/linux/rhel7/
```

### Httpd/Apache server
```
$ chmod -R 0755 /var/www/html/
$ chown -R nobody:nobody /var/www/html/

$ systemctl start httpd
$ systemctl status httpd
```
Note :  Any changes in above folder, then you have to ensure and ammend the file/folder permission as stated above
## Firewall & SElinux
By Default Firewall, Selinux will be running as part security,If you dont want then you have to disable this services
```
$ systemctl stop firewalld
$ systemctl disable firewalld

$ systemctl stop firewalld
$ systemctl disable selinux
```

*If you need above services to run then you have to follow below procedures.*

```
$ semanage fcontext -a -t samba_share_t ‘/var/www/html/windows(/.*)?’
$ semanage fcontext -a -t samba_share_t ‘/var/www/html/linux(/.*)?’

$ restorecon -R -v /var/www/html/linux
$ restorecon -R -v /var/www/html/linux

$ firewall-cmd --add-port=69/udp --permanent
$ firewall-cmd --add-service=dhcp --permanent 
$ firewall-cmd --add-service=http --permanent
$ firewall-cmd --add-service=ftp --permanent
$ firewall-cmd --reload 

>> Run the this command to check the ports are in listen status.

$ netstat -tulpn
```

### At this stage we have done all our configuration setttings at Linux PXE Server. Now we have do prepare the windows bootfiles for PXE environment

## Create WINPE for PXE boot


First step you have to download  windows ADK and install on your windows system (> windows 7 OS release).The link his [here](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install)

_Download and Install Windows Assessment and Deployment Kit_ : 

* [Download the Windows ADK for Windows 10, version 1903](https://go.microsoft.com/fwlink/?linkid=2086042)

* [Download the Windows PE add-on for the ADK](https://go.microsoft.com/fwlink/?linkid=2087112)

For More options of installation  and other tools refer this [link](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install) 

Lets begin to create the winpe images. 
on windows system 
Click windows > All Programs >  Windows kits > Deployment and Imaging Tools Environment

#### Once you got Command prompt window,  

*yip=your_install_path*
```
yip> copype  amd64 c:\winpe_x64

Files will be copied to c:\winpe_x64

yip>Dism /mount-image /imagefile:c:\winpe_x64\media\sources\boot.wim /index:1 /mountdir:C:\winpe_x64\mount

yip>notepad.exe C:\WinPEamd64\mount\Windows\System32\Startnet.cmd
```
_A notepad will get open, update your windows source files location as below_

```
wpeinit

net use z: \\192.168.23.130\windows\2019
z:
z:\setup.exe /unattend:z:\unattend.xml 
```
##### Adding drivers, If you have any specific drivers to add, then open copy those driver files to c:\drivers folder else skip this step


```

yip>dism /image:c:\winpe_x64\mount /Add-Driver /driver:c:\Drivers /recurse
```
#### Mount your boot directory in windows for winPE setup
```
net use z: \\192.168.23.130\windows\
z: 
md boot\Fonts
```

##### Copy windows boot files
```
z:\>copy c:\winpe_x64\mount\windows\boot\pxe\*.* z:\boot\
z:\>copy C:\winpe_x64\media\boot\boot.sdi z:\boot
z:\>copy c:\winpe_x64\media\sources\boot.wim z:\boot
z:\>copy C:\winpe_x64\media\Boot\Fonts z:\boot\Fonts
```
##### Configure boot settings and copy the BCD file
```
yip> bcdedit /createstore c:\BCD
yip> bcdedit /store c:\BCD /create {ramdiskoptions} /d "Ramdisk options"
yip> bcdedit /store c:\BCD /set {ramdiskoptions} ramdisksdidevice boot
yip> bcdedit /store c:\BCD /set {ramdiskoptions} ramdisksdipath \boot\boot.sdi
```
##### This last command will return a GUID,copy this GUID we need to replace in next set of commands.
```
yip> bcdedit /store c:\BCD /create /d "winpe boot image" /application osloader
      - The entry {f54f89457d-sds2-1dv6-j0sd-00s135fa041sd} was successfully created. 

yip> bcdedit /store c:\BCD /set {GUID} device ramdisk=[boot]\boot\boot.wim,{ramdiskoptions} 
yip> bcdedit /store c:\BCD /set {GUID} path \windows\system32\winload.exe 
yip> bcdedit /store c:\BCD /set {GUID} osdevice ramdisk=[boot]\boot\boot.wim,{ramdiskoptions} 
yip> bcdedit /store c:\BCD /set {GUID} systemroot \windows
yip> bcdedit /store c:\BCD /set {GUID} detecthal Yes
yip> bcdedit /store c:\BCD /set {GUID} winpe Yes
yip> bcdedit /store c:\BCD -displayorder {GUID} -addlast

yip> bcdedit /store c:\BCD /create {bootmgr} /d "boot manager"
yip> bcdedit /store c:\BCD /set {bootmgr} timeout 30 
```
##### To know your BCD config file
```
yip>  bcdedit /store C:\BCD /enum all

yip> dism /unmount-image /mountdir:c:\winpe_x64\mount /commit
```
##### Now copy this BCD file to boot location
```
yip> copy c:\BCD z:\boot\bcd
```
### Your winpe setup is ready. 

Disconnect your drive
```
yip> net use x: /delete 
```

## Warm up and Ready to rockon your windows pxe boot from linux server via UEFI 
