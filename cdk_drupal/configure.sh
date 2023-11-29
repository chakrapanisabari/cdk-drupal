#!/bin/bash
sudo apt-get update 
sudo apt-get upgrade
sudo apt install -y php8.1
sudo apt install php8.1 php8.1-fpm php8.1-mysql php-common php8.1-cli php8.1-common php8.1-opcache php8.1-readline php8.1-mbstring php8.1-xml php8.1-gd php8.1-curl

#Installing nginx
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl status nginx
sudo systemctl enable nginx
sudo apt update -y
sudo apt install -y jq

#MySQL Installation
sudo apt install mysql-server
sudo mysql_secure_installation -y
sudo systemctl start mysql
sudo systemctl enable mysql

sudo systemctl start php8.1-fpm
sudo systemctl enable php8.1-fpm
sudo systemctl status php8.1-fpm
sudo tee /etc/php/8.1/fpm/php.ini<<'EOF'
upload_max_filesize = 32M
post_max_size = 48M
memory_limit = 256M
max_execution_time = 600
max_input_vars = 3000
max_input_time = 1000
EOF

sudo systemctl restart php8.1-fpm

# x=$(echo "${rds_endpt}" | cut -d':' -f1)
# echo $x
# sudo mysql -h "$x" -P 3306 -u drupaladmin -predhat22 -e "CREATE DATABASE drupal; CREATE USER 'drupaluser'@'%' IDENTIFIED BY 'drupalpass'; GRANT ALL  ON drupal.* TO 'drupaluser'@'%' IDENTIFIED BY 'drupalpass' WITH GRANT OPTION; FLUSH PRIVILEGES; EXIT;"

cd /tmp && wget https://ftp.drupal.org/files/projects/drupal-10.1.6.tar.gz
sudo tar -zxvf drupal-10.1.6.tar.gz 
sudo mv drupal-10.1.6 drupal
cp -r ./drupal /var/www/html/
cd /var/www/html/
sudo chown -R nginx:nginx /var/www/html/
sudo chmod -R 755 /var/www/html/
sudo rm -rf /etc/nginx/nginx.*
sudo tee /etc/nginx/nginx.conf<<'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events
{
  worker_connections 1024;
}

http
{
  log_format main '$remote_addr - $remote_user [$time_local] "$request" '
  '$status $body_bytes_sent "$http_referer" '
  '"$http_user_agent" "$http_x_forwarded_for"';

  access_log /var/log/nginx/access.log main;

  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 65;
  types_hash_max_size 4096;

  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  # Load modular configuration files from the /etc/nginx/conf.d directory.
  # See http://nginx.org/en/docs/ngx_core_module.html#include
  # for more information.
  include /etc/nginx/conf.d/*.conf;

  server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name demo.sabari.me;
    root /var/www/html/drupal; ## <-- Your only path reference.

    add_header X-Frame-Options "SAMEORIGIN";

    client_max_body_size 1000M;


    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # Very rarely should these ever be accessed outside of your lan
    location ~* \.(txt|log)$ {
        allow 192.168.0.0/16;
        deny all;
    }

    location ~ \..*/.*\.php$ {
        return 403;
    }

   location ~ ^/sites/.*/private/ {
        return 403;
    }

    # Block access to scripts in site files directory
    location ~ ^/sites/[^/]+/files/.*\.php$ {
        deny all;
    }

    # Allow "Well-Known URIs" as per RFC 5785
    location ~* ^/.well-known/ {
        allow all;
    }

    # Block access to "hidden" files and directories whose names begin with a
    # period. This includes directories used by version control systems such
    # as Subversion or Git to store control files.
    location ~ (^|/)\. {
        return 403;
    }

    location / {
        try_files $uri /index.php?$query_string; # For Drupal >= 7
    }

    location @rewrite {
        rewrite ^/(.*)$ /index.php?q=$1;
    }


   # Don't allow direct access to PHP files in the vendor directory.
    location ~ /vendor/.*\.php$ {
        deny all;
        return 404;
    }


    # In Drupal 8, we must also match new paths where the '.php' appears in
    # the middle, such as update.php/selection. The rule we use is strict,
    # and only allows this pattern with the update.php front controller.
    # This allows legacy path aliases in the form of
    # blog/index.php/legacy-path to continue to route to Drupal nodes. If
    # you do not have any paths like that, then you might prefer to use a
    # laxer rule, such as:
    #   location ~ \.php(/|$) {
    # The laxer rule will continue to work if Drupal uses this new URL
    # pattern with front controllers other than update.php in a future
    # release.
    location ~ '\.php$|^/update.php' {
        fastcgi_split_path_info ^(.+?\.php)(|/.*)$;
        # Security note: If you're running a version of PHP older than the
        # latest 5.3, you should have "cgi.fix_pathinfo = 0;" in php.ini.
        # See http://serverfault.com/q/627903/94922 for details.
        include fastcgi_params;
        # Block httpoxy attacks. See https://httpoxy.org/.
        fastcgi_param HTTP_PROXY "";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param QUERY_STRING $query_string;
        fastcgi_intercept_errors on;
        # PHP 5 socket location.
        #fastcgi_pass unix:/var/run/php5-fpm.sock;
        # PHP 7 socket location.
        fastcgi_pass unix:/var/run/php-fpm/www.sock;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_NAME      $fastcgi_script_name;
        fastcgi_param  REQUEST_METHOD   $request_method;
        fastcgi_param  CONTENT_TYPE     $content_type;
        fastcgi_param  CONTENT_LENGTH   $content_length;
        fastcgi_ignore_client_abort     off;
        fastcgi_keep_conn on;
        fastcgi_connect_timeout 600;
        fastcgi_send_timeout 600;
        fastcgi_read_timeout 600;
        fastcgi_buffer_size 2048k;
        fastcgi_buffers 4 1024k;
        fastcgi_busy_buffers_size 2048k;
        fastcgi_temp_file_write_size 2048k;
    }

    # Fighting with Styles? This little gem is amazing.
    location ~ ^/sites/.*/files/styles/ { # For Drupal >= 7
        try_files $uri @rewrite;
    }

    # Handle private files through Drupal. Private file's path can come with a language prefix.
    location ~ ^(/[a-z\-]+)?/system/files/ { # For Drupal >= 7
        try_files $uri /index.php?$query_string;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        try_files $uri @rewrite;
        expires max;
        log_not_found off;
    }}}
EOF

sudo systemctl restart nginx

cd /var/www/html/drupal/

sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo php -r "if (hash_file('sha384', 'composer-setup.php') === 'e21205b207c3ff031906575712edab6f13eb0b361f2085f1f1237b7126d785e826a450292b6cfd1d64d92e6563bbde02') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php composer-setup.php
sudo php -r "unlink('composer-setup.php');"