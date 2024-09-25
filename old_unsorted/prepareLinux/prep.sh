#!/bin/bash

libs_list=( tree git gawk iproute2 xvfb make net-tools libncurses5-dev tftpd libssl-dev zlib1g:i386 flex bison libselinux1 gnupg wget 
	    diffstat chrpath socat xterm autoconf libtool unzip texinfo zlib1g-dev gcc-multilib build-essential libsdl1.2-dev libglib2.0-dev
           screen pax gzip openbsd-inetd python aptitude )

libs4aptitude=( zlib1g-dev gcc-multilib libsdl1.2-dev libglib2.0-dev zlib1g:i386 )

if [ "$(id -u)" != "0" ]; then
	printf "Must be root for execute \n"
	exit 1
fi	

for i in "${libs_list[@]}"
do
	printf "Install: $i \n"
	apt-get install $i
done

for i in "${libs4aptitude[@]}"
do
	printf "Install: $i \n"
	aptitude install $i 
done

printf "Make linke to home dir in media folder\n"
ln -s /home/xilinx/ /media/

printf "Reconfig to bash\n"
dpkg-reconfigure dash

printf "Config tftpd server\n"
mkdir /tftpboot
chown -R nobody:nobody /tftpboot
chmod 777 /tftpboot
# echo "tftp dgram udp wait nobody /usr/sbin/tcpd /usr/sbin/in.tftpd /tftpboot" > /etc/inetd.conf
/etc/init.d/openbsd-inetd restart

printf "If some of packege is not install, use aptitude (sudo apt-get instal aptitude -y; sudo aptidude <pkg_name>)"

