#!/bin/bash

sed -i 's/wlp1s0/wlan0/' kingsizecrack.sh 2> /dev/null
echo "KingSize Cracking Installer"

apt-get install --yes aircrack-ng xfce4-terminal yad reaver isc-dhcp-server
