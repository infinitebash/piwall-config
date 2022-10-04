#!/bin/bash

echo "setting up network"

echo "name this pi: "
read name

echo $name | sudo tee /etc/hostname
echo "127.0.1.1 $name" | sudo tee /etc/hosts

echo "enter pi's ip: "
read ip
echo "enter interface [eth0]: "
read interface
if [[ $interface == "" ]]; then
  interface="eth0"
fi

echo "enter router ip [192.168.1.1]: "
read router
if [[ $router == "" ]]; then
  router="192.168.1.1"
fi

echo "enter dns ip [$router]: "
read dns 
if [[ $dns == "" ]]; then
  dns=$router
fi

echo "configuring piwall"
echo "piwall file to dl [from repo]: "
read config
if [[ $config == "" ]]; then
  config="https://raw.githubusercontent.com/infinitebash/piwall-config/main/.piwall"
fi
wget $config -O ~/.piwall

echo "[tile]
id=$name" | tee ~/.pitile

echo "interface $interface
static ip_address=$ip/24
static routers=$router
static domain_name_servers=$dns" | sudo tee /etc/dhcpcd.conf

echo "ip route add 224.0.0.0/4 via $ip" | sudo tee /lib/dhcpcd/dhcpcd-hooks/40-route

echo "installing packages"
sudo apt update
sudo apt install wget libegl1-mesa-dev -y
wget http://dl.piwall.co.uk/pwlibs1_1.1_armhf.deb
wget http://dl.piwall.co.uk/pwomxplayer_20130815_armhf.deb

sudo dpkg -i pwlibs1_1.1_armhf.deb
sudo dpkg -i pwomxplayer_20130815_armhf.deb

echo "pwomxplayer -A udp://239.0.1.23:1234?buffer_size=1200000B" | tee start.sh
mkdir -p $HOME/.config/systemd/user
echo "[Unit]
Description=Start piwall
After=network.target
[Service]
Type=simple
ExecStart $HOME/start.sh
Restart=always
[Install]
WantedBy=default.target" | tee $HOME/.config/systemd/user/piwall.service

systemctl daemon-reload
systemctl --user enable piwall.service

echo "done, rebooting in 5 seconds"
wait 5
sudo reboot
