# Description
Folder contain scripts for use in xilinx training. 

Supports file for labs: https://www.xilinx.com/training/downloads.html

License info: https://www.xilinx.com/products/design-tools/vivado/vivado-webpack.html

# Instalation
1. Copy to home folder of user file from course folder with selected version
2. Add (or check that line is alreasdy added) to bottom of .bashrc file line:`source ~/xilinx_setup_env.sh`
4. Add user xilinx into dialout group `sudo usermod -a -G dialout xilinx`
5. Reset system

# Additional config
- Create directory for tftp boot: `sudo mkdir /tftpboot`
- Get access for new folder: `sudo chmod 777 /tftpboot`

## CentOS and RedHat
- `sudo yum install tftp-server lftp telnet meld chrpath tree putty`
- `sudo nano /usr/lib/systemd/system/tftp.service`
- Edit ExecStart -s flag values, must point to /tftpboot. (`ExecStart=/usr/sbin/in.tftpd -c -v -u tftp -p -U 117 -s /tftpboot`) 
- Reload service and add to autostart
```
sudo systemctl daemon-reload
sudo systemctl start xinetd
sudo systemctl enable xinetd
sudo systemctl start tftp
sudo systemctl enable tftp
```

## Ubuntu
- `sudo apt install tftpd-hpa lftp telnet meld chrpath tree gtkterm`
- `sudo nano /etc/default/tftpd-hpa`
- TFTP_DIRECTORY must point to /tftpboot
- Reload and add to autostart
```
sudo systemctl restart tftpd-hpa
sudo systemctl enable tftpd-hpa
```

# Additional apps and libs
## Centos/ReadHat
1. Lib PNG 1.6
	* Download source https://sourceforge.net/projects/libpng/
	* Unzip, open terminal and cd to unziped folder
	* `./configure`
	* `make`
	* `sudo make install`
	* `sudo ln -s /usr/local/lib/libpng16.so.16 /usr/lib64/libpng16.so.16`

## Ubuntu
1. Lib PNG 1.6 - `sudo apt-get install -y libpng16-16`
2. Lib JPEG 6.2 - `sudo apt-get install -y libjpeg62`
