# Ubuntu 20.4 LTS Server + nginx + pgadmin4 (server mode + reverse proxy)

### Install pre requisties:
```
sudo apt install build-essential libssl-dev libffi-dev virtualenv python-pip libpq-dev python-dev
```

### Create dir's  &  permissions for pgadmin4 home :
```
sudo mkdir /var/lib/pgadmin4/storage
sudo mkdir -p /var/lib/pgadmin4/sessions
sudo mkdir /var/log/pgadmin4
chown -R tssdev: /var/log/pgadmin4/
chown -R tssdev: /var/lib/pgadmin4/
```

### Enable virtualenv and install pgadmin (currently its 5.2):
```
virtualenv venv39
source venv39/bin/activate
wget https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v5.2/pip/pgadmin4-5.2-py3-none-any.whl
pip install pgadmin4-5.2-py3-none-any.whl

Note : if you installed on non (pip) virtual environment, the path will be different.
```

### Now configure server environment:
```
vi  ~/venv39/lib/python3.9/site-packages/pgadmin4/config_local.py

DEFAULT_SERVER = '0.0.0.0'
DEFAULT_SERVER_PORT = 5050
LOG_FILE = '/var/log/pgadmin4/pgadmin4.log'
SQLITE_PATH = '/var/lib/pgadmin4/pgadmin4.db'
SESSION_DB_PATH = '/var/lib/pgadmin4/sessions'
STORAGE_DIR = '/var/lib/pgadmin4/storage'
SERVER_MODE = True

```

### Setup pgadmin4:
```
python venv39/lib/python3.9/site-packages/pgadmin4/setup.py


NOTE: Configuring authentication for SERVER mode.

Enter the email address and password to use for the initial pgAdmin user account:

Email address: youremail@address.com
Password:xxxxx
Retype password:xxxxx
pgAdmin 4 - Application Initialisation
======================================

```

### Change permission to nginx access:
```
chown -R www-data: /var/lib/pgadmin4/
sudo chown -R www-data: /var/log/pgadmin4/
```

### Now create script to start pgadmin4:
```
vi /usr/local/bin/pgadmin4.sh


#!/bin/bash
. /home/tssdev/venv39/bin/activate
# virtualenv is now active.
#
nohup python /home/tssdev/venv39/lib/python3.9/site-packages/pgadmin4/pgAdmin4.py &

[SHIFT + zz to save file]
chmod +x /usr/local/bin/pgadmin4.sh
```

### Check:
```
$ lsof -nPi  | grep LISTEN
tcp        0      0 0.0.0.0:5050            0.0.0.0:*               LISTEN      27749/python
```

### Configuration of nginx file  pgadmin.conf

server {
       listen 80;

       server_name 127.0.0.1;



    location /pgadmin4/ {
        alias /home/tssdev/venv39/lib/python3.9/site-packages/pgadmin4;
        proxy_set_header X-Script-Name /pgadmin4;
        proxy_set_header Host $host;
        proxy_pass http://localhost:5050/;
        proxy_redirect off;
    }

}

