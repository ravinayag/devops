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

``` lab:~ # yum install  xinetd tftp-server  dhcp syslinux samba samba-common samba-winbind vsftpd httpd  -y```

Note: vsftpd and httpd used for file transfer while network installation either in linux or windows systems.

After spending several days on  research about UEFI + Linux PXE Server + windows pxe boot.

I used iPXE to cover the above requirment you can get more info about this. http://ipxe.org. My special thanks to this team

Let configure the required services from the above package installations.


#### tftpserver
configure tftp server 
vi  /etc/xinet.d/tftp
and modify "disable = no" from yes
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
``

#### dhcpd 
Configure the dhcp server as below   you can lookat the image file 

```
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
option client-arch code 93 = unsigned integer 16;

subnet 192.168.23.0 netmask 255.255.255.0 {
  range 192.168.23.51 192.168.23.60;
  option subnet-mask 255.255.255.0;
  option routers 192.168.23.130, 192.168.23.2;

        class "pxeclients" {
          match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
          next-server 192.168.23.130;

        if option architecture-type = 00:06 {
            filename "uefi/bootia32.efi";
        } else  if option architecture-type!= 00:00 {
            filename "iPXE/ipxe.efi";
            #filename "http:/192.168.23.130/winboot/pxelinux.0";
        } else if option architecture-type = 00:07 or option architecture-type = 00:09 {
            filename "pxelinux.cfg/grubx64.efi";
        } else {
            filename "pxelinux.0";

          }
        }

}
```


#### syslinux 

Copy files from  syslinux directory to tftpboot directory

```#cp -r /usr/share/syslinux/* /var/lib/tftpboot/```

#### ipxe & 
Get the ipxe.efi  and place it to /var/lib/tftpd.
```
wget http://boot.ipxe.org/ipxe.efi
wget http://git.ipxe.org/releases/wimboot/wimboot-latest.zip

```

