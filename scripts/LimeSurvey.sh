#ssh root@ip


sudo apt install nginx -y

sudo systemctl status nginx

sudo systemctl start nginx
sudo systemctl enable nginx

sudo add-apt-repository ppa:ondrej/php

sudo apt install php8.1 php8.1-fpm php8.1-mysql php8.1-xml php8.1-curl php8.1-cli php8.1-mbstring php8.1-zip php8.1-bcmath php8.1-intl php8.1-gd -y

php -v

sudo systemctl start php8.1-fpm
sudo systemctl enable php8.1-fpm


sudo apt install --reinstall php8.1-fpm

sudo apt update
sudo apt install -y software-properties-common

lsb_release -a













