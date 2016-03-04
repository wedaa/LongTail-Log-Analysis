#!/bin/sh
######################################################################
# install_openssh.sh
# Written by: Eric Wedaa
# Version: 1.1
# Last Update: 2016-03-03, added checking so we don't re-add startup
#              lines to /etc/rc.local
#
# LICENSE: GPLV2: Please see the README at 
# https://github.com/wedaa/LongTail-Log-Analysis/blob/master/README.md
#
######################################################################
if [[ $EUID -ne 0 ]]; then
	echo "Sorry, this script must be run as root" 1>&2
	exit 1
fi

if [ -d /usr/local/source/openssh ] ; then
	echo "It looks like you have already installed the LongTail honeypots "
	echo "on this server."
	echo ""
	echo "If you wish to reinstall or install a newer version of the "
	echo "LongTail openssh honeypots, then you need to run the following"
	echo "command:"
	echo "   /bin/rm -rf /usr/local/source/openssh"
	echo "and then run this script again."
	exit;
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
mv sshd.c sshd.c.orig
wget https://raw.githubusercontent.com/wedaa/LongTail-Log-Analysis/master/auth-passwd.c
wget https://raw.githubusercontent.com/wedaa/LongTail-Log-Analysis/master/sshd.c
wget https://raw.githubusercontent.com/wedaa/LongTail-Log-Analysis/master/sshd_config-22
cp sshd_config-22 /usr/local/etc
./configure
make
make install
cp sshd /usr/local/sbin/sshd-22
chmod a+rx sshd /usr/local/sbin/sshd-22
cd ..

######################################################
cd /usr/local/source/openssh
cd openssh-2222
wget http://mirrors.nycbug.org/pub/OpenBSD/OpenSSH/portable/openssh-6.7p1.tar.gz
tar -xf openssh-6.7p1.tar.gz
mv openssh-6.7p1 openssh-6.7p1-2222
cd openssh-6.7p1-2222
wget https://raw.githubusercontent.com/wedaa/LongTail-Log-Analysis/master/auth-passwd-2222.c
mv sshd.c sshd.c.orig
mv auth-passwd.c auth-passwd.c.orig
wget https://raw.githubusercontent.com/wedaa/LongTail-Log-Analysis/master/sshd.c
cp auth-passwd-2222.c auth-passwd.c
wget https://raw.githubusercontent.com/wedaa/LongTail-Log-Analysis/master/sshd_config-2222
cp sshd_config-2222 /usr/local/etc
./configure
make
cp sshd /usr/local/sbin/sshd-2222
chmod a+rx sshd /usr/local/sbin/sshd-2222
cd ..

##################################################
# check to see if it's already in /etc/rc.local
grep ^\/usr\/local\/sbin\/sshd-22\  /etc/rc.local >/dev/null
if [ $? -eq 0 ]; then
    echo "sshd-22 already in /etc/rc.local"
else
	echo ""
	echo "Adding startup line for sshd-22 to /etc/rc.local"
	echo ""
	echo "/usr/local/sbin/sshd-22 -f /usr/local/etc/sshd_config-22 " >> /etc/rc.local
fi

grep ^\/usr\/local\/sbin\/sshd-2222\  /etc/rc.local >/dev/null
if [ $? -eq 0 ]; then
    echo "sshd-2222 already in /etc/rc.local"
else
	echo ""
	echo "Adding startup line for sshd-2222 to /etc/rc.local"
	echo ""
	echo "/usr/local/sbin/sshd-2222 -f /usr/local/etc/sshd_config-2222 " >> /etc/rc.local
fi

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

