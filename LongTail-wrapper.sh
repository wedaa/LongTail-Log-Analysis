#!/bin/sh
function print_divider {
	echo ""
	echo "================================================================"
	echo ""
}

print_divider
START_HOUR=`date +%H` # This is used at the end of the program but we want to know it NOW
if [ $START_HOUR -eq 0 ]; then
	date; /usr/local/etc/LongTail.sh 2222  ; print_divider # This runs first since it's fastest
	date; /usr/local/etc/LongTail.sh  ; print_divider # This should still run at midnight
	date; /usr/local/etc/LongTail.sh ssh blackridge MIDNIGHT ; print_divider
	date; /usr/local/etc/LongTail.sh ssh erhp MIDNIGHT ; print_divider
	date; /usr/local/etc/LongTail.sh ssh erhp2 MIDNIGHT ; print_divider
	date; /usr/local/etc/LongTail.sh ssh shepherd MIDNIGHT ; print_divider
	date; /usr/local/etc/LongTail.sh ssh syrtest MIDNIGHT ; print_divider
	date; /usr/local/etc/LongTail.sh ssh edub MIDNIGHT ; print_divider
	date; /usr/local/etc/LongTail.sh ssh edu_c MIDNIGHT ; print_divider

	date; /usr/local/etc/LongTail.sh 2222 shepherd MIDNIGHT ; print_divider
	date; /usr/local/etc/LongTail.sh 2222 erhp MIDNIGHT ; print_divider
	date; /usr/local/etc/LongTail.sh 2222 erhp2 MIDNIGHT ; print_divider
	date; /usr/local/etc/LongTail.sh 2222 syrtest MIDNIGHT ; print_divider
	date; /usr/local/etc/LongTail.sh 2222 edub MIDNIGHT ; print_divider
	date; /usr/local/etc/LongTail.sh 2222 edu_c MIDNIGHT ; print_divider
	date; /usr/local/etc/LongTail.sh 2222 blackridge MIDNIGHT ; print_divider
else
	date; /usr/local/etc/LongTail.sh  ; print_divider
	date; /usr/local/etc/LongTail.sh ssh blackridge ; print_divider
	date; /usr/local/etc/LongTail.sh ssh erhp ; print_divider
	date; /usr/local/etc/LongTail.sh ssh erhp2 ; print_divider
	date; /usr/local/etc/LongTail.sh ssh shepherd ; print_divider
	date; /usr/local/etc/LongTail.sh ssh syrtest ; print_divider
	date; /usr/local/etc/LongTail.sh ssh edub ; print_divider
	date; /usr/local/etc/LongTail.sh ssh edu_c ; print_divider

	date; /usr/local/etc/LongTail.sh 2222  ; print_divider
	date; /usr/local/etc/LongTail.sh 2222 shepherd ; print_divider
	date; /usr/local/etc/LongTail.sh 2222 erhp ; print_divider
	date; /usr/local/etc/LongTail.sh 2222 erhp2 ; print_divider
	date; /usr/local/etc/LongTail.sh 2222 syrtest ; print_divider
	date; /usr/local/etc/LongTail.sh 2222 edub ; print_divider
	date; /usr/local/etc/LongTail.sh 2222 edu_c ; print_divider
	date; /usr/local/etc/LongTail.sh 2222 blackridge ; print_divider
fi


date; grep blackridge /var/log/messages |egrep -v systemd-logind\|dbus\|\ su: |sed 's/Password:..*$/Password: XXXX/' |sed 's/ RSA..*$//' > /var/www/html/honey/blackridge/current-raw-data.txt
date; grep blackridge /var/log/messages |egrep -v systemd-logind\|dbus\|\ su: |sed 's/Password:..*$/Password: XXXX/'|grep 'blackridge sshd\[' |sed 's/ RSA..*$//' > /var/www/html/honey/blackridge/current-identified-traffic.txt
ONE_AM=1
START_HOUR=`date +%H` # This is used at the end of the program but we want to know it NOW
if [ $START_HOUR -eq $ONE_AM ]; then
	YESTERDAY_YEAR=`date  +"%Y" --date="1 day ago"`
	YESTERDAY_MONTH=`date  +"%m" --date="1 day ago"`
	YESTERDAY_DAY=`date  +"%d" --date="1 day ago"`

	grep blackridge /var/log/messages* |grep $YESTERDAY_YEAR-$YESTERDAY_MONTH-$YESTERDAY_DAY |egrep -v systemd-logind\|dbus\|\ su: |sed 's/Password:..*$/Password: XXXX/'|grep 'blackridge sshd\[' > /var/www/html/honey/blackridge/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/identified_traffic.data
	cat /var/www/html/honey/blackridge/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/identified_traffic.data |grep Accepted\ publickey\ for\ wedaa |wc -l > /var/www/html/honey/blackridge/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/identified_traffic.data.count
fi


#date; /usr/local/etc/LongTail_analyze_attacks-2222.pl ; print_divider

#date; /usr/local/etc/LongTail.sh telnet shepherd ; print_divider
#date; /usr/local/etc/LongTail.sh telnet erhp ; print_divider
#date; /usr/local/etc/LongTail.sh telnet erhp2 ; print_divider
#date; /usr/local/etc/LongTail.sh telnet ; print_divider
