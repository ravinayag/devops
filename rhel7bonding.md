# Creating the Network Bonding using nmcli

## 1. Creating the Bonding interface

1. Use the nmcli connection command without any arguments to view the existing network connections. 
You can shorten the “connection” argument to “con“. Example:
```bash
# nmcli connection 
NAME                UUID                                  TYPE            DEVICE 
ens32               54561d18-98ed-7c3c-97e0-6c9e2367765f  802-3-ethernet  ens32  
ens35               hd9fere5-7456-h678-f568-467625659568  802-3-ethernet  ens35
```

2. Include the “add type bond” arguments, and any additional information to create a network bond connection. 
The following example creates a bonded interface named bond0, defines the interface as bond0, sets the mode to “active-backup“, and 
assigns an IP address to the bonded interface.

```bash
# nmcli con add type bond con-name bond0 ifname bond0 mode active-backup ip4 192.168.1.11/24
Connection 'bond0' (7h77e8f8-gj80-4167-8176-g78b4a7518n8) successfully added.
The nmcli con command shows the new bond connection.

# nmcli connection 
NAME                UUID                                  TYPE            DEVICE 
bond0               7h77e8f8-gj80-4167-8176-g78b4a7518n8  bond            bond0  
ens32               54561d18-98ed-7c3c-97e0-6c9e2367765f  802-3-ethernet  ens32  
ens35               hd9fere5-7456-h678-f568-467625659568  802-3-ethernet  ens35
```

3. The ‘nmcli con add type bond’ command creates an interface configuration file in the /etc/sysconfig/network-scripts directory. For example:
```bash
# cat /etc/sysconfig/network-scripts/ifcfg-bond0
DEVICE=bond0
BONDING_OPTS=mode=active-backup
TYPE=Bond
BONDING_MASTER=yes
BOOTPROTO=none
IPADDR=192.168.1.11
PREFIX=24
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=bond0
UUID=7h77e8f8-gj80-4167-8176-g78b4a7518n8
ONBOOT=yes
```

4. The ip addr command shows the new bond0 interface:
```bash
# ip addr show bond0
5: bond0: [BROADCAST,MULTICAST,MASTER,UP] mtu 1500 qdisc noqueue state DOWN qlen 1000
    link/ether 00:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.11/24 brd 192.168.1.255 scope global bond0
       valid_lft forever preferred_lft forever
```

## 2. Creating the Slave Interfaces

For each interface that you want to bond, use the ‘nmcli con add type bond-slave‘ command. 
The following example adds the ens32 interface as a bond slave. The command does not include the con-name 
argument so a name is automatically generated. 
```bash
1. You can have the name set for the slave interfaces with the con-name argument.
# nmcli con add type bond-slave ifname ens32 master bond0
Connection 'bond-slave-ens32' (7s64e8h8-gr80-4567-8236-g73fgt618n8f) successfully added.


2. The following example adds the ens35 interface as a “bond-slave“.
# nmcli con add type bond-slave ifname ens35 master bond0
Connection 'bond-slave-ens35' (f5298a46-g3de-4782-bg46-ef760345fgg6) successfully added.

3. The nmcli con command shows the new connections.

# nmcli connection 
NAME                UUID                                  TYPE            DEVICE 
bond0               7h77e8f8-gj80-4167-8176-g78b4a7518n8  bond            bond0  
ens32               54561d18-98ed-7c3c-97e0-6c9e2367765f  802-3-ethernet  ens32  
ens35               hd9fere5-7456-h678-f568-467625659568  802-3-ethernet  ens35  
bond-slave-ens32    7s64e8h8-gr80-4567-8236-g73fgt618n8f  802-3-ethernet  --     
bond-slave-ens35    f5298a46-g3de-4782-bg46-ef760345fgg6  802-3-ethernet  --   

4. The nmcli con add type bond-slave commands create interface configuration files in the /etc/sysconfig/network-scripts directory. For example:
# cat /etc/sysconfig/network-scripts/ifcfg-bond-slave-ens32
TYPE=Ethernet
NAME=bond-slave-ens32
UUID=7s64e8h8-gr80-4567-8236-g73fgt618n8f
DEVICE=ens32
ONBOOT=yes
MASTER=bond0
SLAVE=yes
# cat /etc/sysconfig/network-scripts/ifcfg-bond-slave-ens35
TYPE=Ethernet
NAME=bond-slave-ens35
UUID=f5298a46-g3de-4782-bg46-ef760345fgg6
DEVICE=ens35
ONBOOT=yes
MASTER=bond0
SLAVE=yes

5. The ip addr command includes “SLAVE” for the ens32 and ens35 interfaces and also includes “master bond0“.
``` 

## 3. Activating the Bond

You can use the nmcli command to bring up the connections. Bring up the slaves first, and then bring up the bond interface. 
```bash
1. The following commands bring up the slaves:
# nmcli connection up bond-slave-ens32
# nmcli connection up bond-slave-ens35

2. The following command brings up the bond0 interface:
# nmcli con up bond0

3. The ip addr command, or the ip link command, now shows the slave and the bond interfaces that are UP.
# ip link
2: ens32: [BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP] mtu 1500 qdisc pfifo_fast master bond0 state UP mode DEFAULT qlen 1000
    link/ether 00:0c:23:78:g7:25 brd ff:ff:ff:ff:ff:ff
3: ens35: [BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP] mtu 1500 qdisc pfifo_fast master bond0 state UP mode DEFAULT qlen 1000
    link/ether 00:0c:23:78:g7:25 brd ff:ff:ff:ff:ff:ff
4: bond0: [BROADCAST,MULTICAST,MASTER,UP,LOWER_UP] mtu 1500 qdisc noqueue state UP mode DEFAULT qlen 1000
    link/ether 00:0c:23:78:g7:25 brd ff:ff:ff:ff:ff:ff
```
## 4. Viewing Network Bonding Information

```bash
1. Each network interface contains a directory in the /sys/class/net directory.
For example:
# ls /sys/class/net
bond0  bonding_masters  ens32  ens35  lo

2. In this example, a network bond named ‘bond0’ exists. A directory of the same name exists that contains configuration information for that bond. 
For example:
# ls /sys/class/net/bond0
addr_assign_type  bonding    carrier_changes  dormant  gro_flush_timeout  iflink       lower_ens35   operstate     queues      subsystem     uevent
address           broadcast  dev_id           duplex   ifalias            link_mode    mtu           phys_port_id  speed       tx_queue_len
addr_len          carrier    dev_port         flags    ifindex            lower_ens32  netdev_group  power         statistics  type

3. Within this directory is a bonding directory that contains information for the bond0 interface.
For example:
# ls /sys/class/net/bond0/bonding
active_slave       ad_aggregator   ad_select          arp_interval   fail_over_mac  mii_status    num_unsol_na       queue_id        updelay
ad_actor_key       ad_num_ports    ad_user_port_key   arp_ip_target  lacp_rate      min_links     packets_per_slave  resend_igmp     use_carrier
ad_actor_sys_prio  ad_partner_key  all_slaves_active  arp_validate   lp_interval    mode          primary            slaves          xmit_hash_policy
ad_actor_system    ad_partner_mac  arp_all_targets    downdelay      miimon         num_grat_arp  primary_reselect   tlb_dynamic_lb

4. There are also directories that contain information for each of the slaves. 
For example:
# ls /sys/class/net/bond0/lower_ens32
addr_assign_type  bonding_slave  carrier_changes  dev_port  flags              ifindex    master        operstate     queues      subsystem     uevent
address           broadcast      device           dormant   gro_flush_timeout  iflink     mtu           phys_port_id  speed       tx_queue_len  upper_bond0
addr_len          carrier        dev_id           duplex    ifalias            link_mode  netdev_group  power         statistics  type
```
```bash
5. Following are some examples of viewing files in the /sys/class/net directory.
# cat /sys/class/net/bonding_masters
bond0
# cat /sys/class/net/bond0/operstate
up
# cat /sys/class/net/bond0/address
00:0c:23:78:g7:25
# cat /sys/class/net/bond0/bonding/active_slave
ens32
# cat /sys/class/net/bond0/bonding/mode
active-backup 1
# cat /sys/class/net/bond0/bonding/slaves
ens32 ens35

6. Following is an example of viewing the /proc/net/bonding/bond0 file.
# cat /proc/net/bonding/bond0

Bonding Mode: fault-tolerance (active-backup)
Primary Slave: None
Currently Active Slave: ens32
MII Status: up
MII Polling Interval (ms): 100
Up Delay (ms): 0
Down Delay (ms): 0

Slave Interface: ens32
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 00:0c:23:78:g7:25
Slave queue ID: 0

Slave Interface: ens35
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 00:0c:49:54:r5:37
Slave queue ID: 0
```

## 5. How to disable IPv4 or IPv6 on bonded interface
These steps are only needed if bond1 will not use an ipv4 or ipv6 address
```bash
# nmcli connection modify bond1 ipv4.method disabled
and/or
# nmcli connection modify bond1 ipv6.method ignore
```
