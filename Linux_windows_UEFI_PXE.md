## PXE SERVER LINUX WINDOWS 10 /2019 UEFI BIOS
I was asked by my client to setup the Linux PXE server with windows 10 / 2019 bootable clients with UEFI BIOS.  
since im not experienced system administrator on Windows platform,  
but i can able to manage the requirement and complete the ASK

HERE im going to over only about UEFI BIOS, AS there are many docs available over the internet for non UEFI BIOS Based systems. 

#### Environment :
I used cent OS 7 as PXE Server to server linux and windows systems.
Client machines :  vmware or physical machines running machines with UEFI based.

#### Prerequieste for linux server ( PXE Server)

I have skipped the Installation of Linux server and ip configuarations. I you have to configure a static ip for dhcp services.

```
yum install syslinux
lab:~ # yum install syslinux tftp-server samba samba-common samba-winbind vsftpd httpd
lab:~ # yum install samba samba-common samba-winbind 

```
Note : vsftpd and httpd used for file transfer while network installation either in linux or windows systems.

After spending several days on  research about UEFI + Linux PXE Server + windows pxe boot.

I used iPXE to cover the above requirment you can get more info about this. http://ipxe.org. My special thanks to this team
