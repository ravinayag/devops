# MySQL DB access only from Workstation with dynamic address with full security, Do at your own risk.

I have a task to access the Mysql server from one work station (MySQL workbench) and other clients' machines should not have to access the server and users should log in through one system.

Note: Since MySQL recommends to use IP instead of FQDN, but the requirement is to have like this due to the development environment.

With that goal and the challenge comes that workstation IP address will keep change as part Dynamic IP address pool over the Internet.

[Picture](link)

Lets get into action to server setup and configuration.
1, Ensure you done with all prerequisites. i.e Install Mysql server, and Firewall open for Mysql port 3306, Install Mysql Server from apt install I used ubuntu 16 and windows system as a client.
```
caravi@lab:~$ cat /etc/mysql/mysql.conf.d/mysqld.cnf
#
# The MySQL database server configuration file.
#
……..
[mysqld]
#
# * Basic Settings
#
user = mysql
pid-file = /var/run/mysqld/mysqld.pid
socket = /var/run/mysqld/mysqld.sock
port = 3306
basedir = /usr
datadir = /var/lib/mysql
tmpdir = /tmp
lc-messages-dir = /usr/share/mysql
skip-external-locking
#
# Instead of skip-networking the default is now to listen only on
# localhost which is more compatible and is not less secure.
#bind-address = 127.0.0.1
bind-address = 0.0.0.0
```
Change bind-address to 0.0.0.0 any ethernet interface from only localhost access.

### 2, Now login database :
```
$ mysql -u root -p 
mysql> SELECT User, Host from mysql.user;
+ — — — — — — — — — + — — — — — -+
| User | Host |
+ — — — — — — — — — + — — — — — -+
| debian-sys-maint | localhost |
| mysql.session | localhost |
| mysql.sys | localhost |
| phpmyadmin | localhost |
| root | localhost |
+ — — — — — — — — — + — — — — — -+
5 rows in set (0.00 sec)
```
### 2a, Create a new user and provide grant access

```
mysql> CREATE USER ‘db_user’@’knowledgesociety.hopto.org’ IDENTIFIED BY ‘your-password’;
Query OK, 0 rows affected (0.00 sec)
mysql> GRANT ALL PRIVILEGES ON *.* to ‘db_user’@’knowledgesociety.hopto.org’ identified by your-‘password’;
Query OK, 0 rows affected, 1 warning (0.00 sec)
Now review :
mysql> SELECT User, Host from mysql.user;
+ — — — — — — — — — + — — — — — — — — — — — — — — +
| User | Host |
+ — — — — — — — — — + — — — — — — — — — — — — — — +
| db_user | knowledgesociety.hopto.org |
| debian-sys-maint | localhost |
| mysql.session | localhost |
| mysql.sys | localhost |
| phpmyadmin | localhost |
| root | localhost |
+ — — — — — — — — — + — — — — — — — — — — — — — — +
mysql> SHOW GRANTS for ‘db_user’@’knowledgesociety.hopto.org’;
+ — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — -+
| Grants for db_user@knowledgesociety.hopto.org |
+ — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — -+
| GRANT ALL PRIVILEGES ON *.* TO ‘db_user’@’knowledgesociety.hopto.org’ WITH GRANT OPTION |
+ — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — -+
1 row in set (0.00 sec)
mysql>FLUSH PRIVILEGES;
Come out from mysql client and restart mysql server service.
$ sudo service mysql restart
```
### 3, Name Service check 
Now ensure the names services lookup hierarchy, it should be like this in our scenario, pointing files first.
hosts: files dns
networks: files

### 4, Register static FQDN with dynamic IP
Register your domain with the help of No ip . org , they provide 1 free Dynamic DNS. Register your domain name, Here i registered and have as knowledgesociety.hopto.org.
You need to download the no ip tool to run on your client machine for ip address changes, ensure this service is running in the background.

### 5, Now get the IP address of your server, domain or with FQDN
```
i@lab:~$ getent hosts knowledgesociety.hopto.org
149.129.178.119 knowledgesociety.hopto.org
```
update this entry to /etc/hosts file for name resolution, if you not doing this you end with an error at database access from a remote machine.
you can also put this into cron schedule by a script to update every day, so it reflects with new IP address changes.
Here is my script schedule at every update in cron.
#### crontab entry
``` 
$ * 1 * * * /myscript.sh
```
#### script created to add Dynamic DNS for reverse lookup for mysql access.
```
sed ‘/knowledgesociety.hopto.org/d’ /etc/hosts > /etc/hosts.new
cp -p /etc/hosts.new /etc/hosts
getent hosts pragmatic.hopto.org >> /etc/hosts
```
### Tips:
Additionally, you can add up the Firewall rules (iptables/ufw) to give access to the port-specific only to the FQDN provide above. This will cover OS security.
