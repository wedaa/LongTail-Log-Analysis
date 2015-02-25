#!/bin/sh
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

mkdir -p /usr/local/source/openssh
cd /usr/local/source/openssh
mkdir openssh-22
mkdir openssh-2222

######################################################
cd openssh-22
wget http://mirrors.nycbug.org/pub/OpenBSD/OpenSSH/portable/openssh-6.7p1.tar.gz
tar -xf openssh-6.7p1.tar.gz
mv openssh-6.7p1 openssh-6.7p1-22
cd openssh-6.7p1-22
mv auth-passwd.c auth-passwd.c.orig
wget https://raw.githubusercontent.com/wedaa/LongTail-Log-Analysis/master/auth-passwd.c
wget https://raw.githubusercontent.com/wedaa/LongTail-Log-Analysis/master/sshd_config-22
./configure
make
make install
cp sshd /usr/local/sbin/sshd-22
chmod a+rx sshd /usr/local/sbin/sshd-22
cd ..

######################################################
cd openssh-2222
wget http://mirrors.nycbug.org/pub/OpenBSD/OpenSSH/portable/openssh-6.7p1.tar.gz
tar -xf openssh-6.7p1.tar.gz
mv openssh-6.7p1 openssh-6.7p1-2222
cd openssh-6.7p1-2222
wget https://raw.githubusercontent.com/wedaa/LongTail-Log-Analysis/master/auth-passwd-2222.c
mv auth-passwd.c auth-passwd.c.orig
cp auth-passwd-2222.c auth-passwd.c
wget https://raw.githubusercontent.com/wedaa/LongTail-Log-Analysis/master/sshd_config-2222
./configure
make
cp sshd /usr/local/sbin/sshd-2222
chmod a+rx sshd /usr/local/sbin/sshd-2222
cd ..

echo "/usr/local/sbin/sshd-22 -f /usr/local/etc/sshd_config-22 " >> /etc/rc.local
echo "/usr/local/sbin/sshd-2222 -f /usr/local/etc/sshd_config-2222 " >> /etc/rc.local

echo "Please edit /etc/ssh/sshd_config to change the port number to something"
echo "other than port 22 (like something above 48000)."
echo ""
echo "Then run service sshd restart and check that you can login to your server"
echo "On that port."
echo ""
echo "Once you do that, then run the following two commands (Which are also in "
echo "your /etc/rc.local file so they run on reboot."
echo ""
echo "/usr/local/sbin/sshd-22 -f /usr/local/etc/sshd_config-22 " 
echo "/usr/local/sbin/sshd-2222 -f /usr/local/etc/sshd_config-2222 "

echo ""
echo "If this failed, you might need to run the following commands:"
echo "yum install zlib-devel "
echo "yum install openssl-devel "
echo ""

