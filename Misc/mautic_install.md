# Install / Configure Mautic on Ubuntu 18.04 LTS with Nginx, MysqlDB and PHP 7.2

Mautic is an open source, self-hosted marketing automation software based on PHP with huge Community support base.It is designed from the ground up for ease of use to make marketing automation decisions as intuitive as possible.

If you’re looking for a robust marketing automation software to use in your environments, you’ll find Mautic to be useful.
This brief tutorial is going to show new users how to install Mautic on Ubuntu 18.04 LTS with Nginx, MysqlDB and PHP support.

This post covers installing the 2.15.3 version of Mautic followed by upgrading to 2.16 / 3.0

## To get started with installing Mautic, follow the steps below:

### Step 1: Install Nginx Web Server
Mautic requires a webserver to function, im using nginx, So, go and install Nginx on Ubuntu by running the commands below:
```
sudo apt install nginx
```

Next, run the commands below to stop, start and enable Nginx service to always start up with the server boots.
```
sudo systemctl stop nginx.service
sudo systemctl start nginx.service
sudo systemctl enable nginx.service
```

### Step 2: Install MysqlDB Database Server
Mautic also requires a database server to function.. and MysqlDB database server is a great place to start. To install it run the commands below.
```
sudo apt-get install mariadb-server mariadb-client
```
After installing, the commands below can be used to stop, start and enable MysqlDB service to always start up when the server boots.
```
sudo systemctl stop mysql.service
sudo systemctl start mysql.service
sudo systemctl enable mysql.service
```
You can secure installation from below script. Answer the questions for secure.
```
sudo mysql_secure_installation
sudo systemctl restart mysql.service
```
### Step 3: Install PHP 7.2-FPM and Related Modules
Since PHP 7.2 isn’t on Ubuntu default repositories… you will have to get it from third-party repositories.

Run the commands below to add the below third party repository for PHP 7.2
```
sudo apt update
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:ondrej/php
```
Run the commands below to install PHP 7.1 and related modules.
```
sudo apt install php7.2-fpm php7.2-common php7.2-mbstring php7.2-xmlrpc php7.2-soap php7.2-gd php7.2-xml php7.2-intl 
php7.2-mysql php7.2-cli php7.2-zip php7.2-curl php7.2-bcmath php-amqplib php-mbstring
```
Once PHP Modules installed, Configure PHP-FPM file.

```
sudo nano /etc/php/7.2/fpm/php.ini
```
Then make the change the following lines below in the file and save.

```
file_uploads = On
allow_url_fopen = On
memory_limit = 512M
upload_max_filesize = 64M
max_execution_time = 360
cgi.fix_pathinfo = 0
date.timezone = India/kolkata
```

### Step 4: Create Mautic Database  ( Optional) 

Create a blank Mautic database called 'mautic215', and username 'mauticuser'  and provide all permissions to the user.

```
 sudo mysql -u root -p
 CREATE DATABASE mautic215 DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
 CREATE USER 'mauticuser'@'localhost' IDENTIFIED BY 'pa$$word';
 GRANT ALL ON mautic215.* TO 'mauticuser'@'localhost' IDENTIFIED BY 'pa$$word' WITH GRANT OPTION;
 FLUSH PRIVILEGES;
 EXIT;
 ```
 
### Step 5: Download Mautic onto Your Ubuntu 18.04 box

If you go to the official website to download Mautic, you are required to enter your name and email address.
If that’s not what you like, then download the stable version (2.15.3) using the following command.
 
```
sudo wget https://github.com/mautic/mautic/releases/download/2.15.3/2.15.3.zip
 
unzip latest -d /var/www/html/mautic215

sudo chown -R www-data:www-data /var/www/html/mautic215
sudo find -type f -exec chmod 644 {} \;   
sudo find -type d -exec chmod 755 {} \;   
```


### Step 6:  Configure Nginx web server, then create a server block file for Mautic. 
Finally, configure Nginx site configuration file for Mautic. This file will control how users access Mautic content.


```
sudo nano /etc/nginx/conf.d/mautic.conf
```
Copy and paste the content below into the file and save it. Replace the domain name, SSL Keys
```
server {
    root /var/www/html/mautic215;
    index index.php;
    server_name mautic.mydomain.com www.mautic.mydomain.com;
    error_log /var/log/nginx/mautic.error;
    access_log /var/log/nginx/mautic.access;
    location / {
        # try to serve file directly, fallback to app.php
        try_files $uri /index.php$is_args$args;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
    }
    location ~ \.php($|/) {
        include /etc/nginx/fastcgi_params;
        include fastcgi_params;
        # POST requests and urls with a query string should always go to PHP
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param URI $uri;
        fastcgi_param SERVER_NAME $host;
        fastcgi_param REQUEST_METHOD $request_method;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_read_timeout 300;
        fastcgi_ignore_headers Expires Cache-Control;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 256 16k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
    }
    listen 443 ssl;
# managed by Certbot
    ssl_certificate /etc/letsencrypt/live/mydomain/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/mydomain/privkey.pem; # managed by Certbot

    include /etc/letsencrypt/options-ssl-nginx.conf;

}
server {
    if ($host = mautic.mydomain.com) {
        return 301 https://$host$request_uri;
    }
# managed by Certbot
    listen 80;
    server_name mautic.mydomain.com www.mautic.mydomain.com;
    return 404;
}

```

Then test nginx configuration and restart.

After configuring the above, enable it by running the commands below
sudo ln -s /etc/nginx/sites-available/mautic.conf /etc/nginx/sites-enabled/

```sudo nginx -t  ``` 

If no errors,  restart the nginx

```sudo systemctl restart nginx```

### Step 7: Finish Mautic Installation in Web Browser
Now in your browser address bar, type your domain name for Mautic to access the web install wizard.

mautic.mydomain.com

or

mautic.mydomain.com/index.php/installer

Here you can choose the Database which you created. else you should use DBadmin user to create new DB. 

### Troubleshooting 

1, If Mautic is not showing in webbrowser and giving the errors : 403, 500, 404

Check the logs at  
```
sudo tail /var/log/nginx/mautic.error 
sudo tail /var/log/nginx/mautic.access
Clean the folder : rm -f /var/www/html/mautic215/app/cache
```

2, Check the ownership or rerun the below commands
```
sudo chown -R www-data:www-data /var/www/html/mautic215
sudo find . -type f -not -perm 644 -exec chmod 644 {} +
sudo find . -type d -not -perm 755 -exec chmod 755 {} +

```
