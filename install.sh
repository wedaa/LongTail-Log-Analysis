#!/bin/sh

echo "You need to edit LongTail.sh.  Please see LongTail.sh for details"
echo ""
echo "You need to edit this file for SCRIPT_DIR, HTML_DIR, OWNER,"
echo "OBFUSCATE_IP_ADDRESSES, OBFUSCATE_URLS."

echo "And then comment out the exit statement"
exit

SCRIPT_DIR="/usr/local/etc"    # Where do we put the scripts?
HTML_DIR="/var/www/html/honey" # Where do we put the HTML files?
OWNER="wedaa"                  # What is the owner of the process running LongTail?

mkdir -p $HTML_DIR/historical/`date +%Y`/`date +%m`/`date +%d`
mkdir $HTML_DIR/dashboard

OTHER_DIRS=" /var/www/html/honey-2222 /var/www/html/honey-22 /var/www/html/telnet /var/www/html/ftp /var/www/html/rlogin"
for dir in $OTHER_DIRS ; do
	mkdir $dir
	chown $OWNER $dir
	chmod a+rx $dir
done

cp LongTail_dashboard.pl $SCRIPT_DIR
cp LongTail_password_analysis.pl $SCRIPT_DIR
cp LongTail_analyze_attacks.pl $SCRIPT_DIR
cp catall.sh $SCRIPT_DIR
cp ip-to-country $SCRIPT_DIR
cp LongTail.sh $SCRIPT_DIR
cp LongTail_make_graph.php $SCRIPT_DIR
cp LongTail_make_dashboard_graph.php $SCRIPT_DIR
cp translate_country_codes.sed $SCRIPT_DIR
cp LongTail_make_daily_attacks_chart.pl $SCRIPT_DIR
#cp translate_country_codes.sed.orig $SCRIPT_DIR
cp whois.pl $SCRIPT_DIR

for dir in $HTML_DIR $OTHER_DIRS ; do
	cp index.shtml $dir
	cp index-long.shtml $dir
	cp index-historical.shtml $dir
	cp graphics.shtml $dir
	cp header.html $dir
	cp footer.html $dir
	cp notes.shtml $dir
	cp LongTail.css $dir
done

cp dashboard-index.shtml $HTML_DIR/dashboard/index.shtml
cp dashboard-1.shtml $HTML_DIR/dashboard/ 
cp dashboard.shtml $HTML_DIR/
echo "0" > $HTML_DIR/dashboard/count

if [ ! -e $SCRIPT_DIR/LongTail-exclude-accounts.grep ] ; then
	echo "LongTail-exclude-accounts.grep not in $SCRIPT_DIR"
	cp LongTail-exclude-accounts.grep $SCRIPT_DIR
fi

if [ ! -e $SCRIPT_DIR/LongTail-exclude-IPs-httpd.grep ] ; then
	echo "LongTail-exclude-IPs-httpd.grep not in $SCRIPT_DIR"
	cp LongTail-exclude-IPs-httpd.grep $SCRIPT_DIR
fi

if [ ! -e $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep ] ; then
	echo "LongTail-exclude-IPs-ssh.grep not in $SCRIPT_DIR"
	cp LongTail-exclude-IPs-ssh.grep $SCRIPT_DIR
fi

if [ ! -e $SCRIPT_DIR/LongTail-exclude-webpages.grep ] ; then
	echo "LongTail-exclude-webpages.grep not in $SCRIPT_DIR"
	cp LongTail-exclude-webpages.grep $SCRIPT_DIR
fi

chmod a+rx $SCRIPT_DIR/LongTail_dashboard.pl
chmod a+rx $SCRIPT_DIR/LongTail_password_analysis.pl 

chmod a+rx catall.sh $SCRIPT_DIR/catall.sh
chmod a+r ip-to-country $SCRIPT_DIR/ip-to-country
chown $OWNER $SCRIPT_DIR/ip-to-country

chmod a+rx $SCRIPT_DIR/LongTail_analyze_attacks.pl
chmod a+r $SCRIPT_DIR/LongTail-exclude-accounts.grep
chmod a+r $SCRIPT_DIR/LongTail-exclude-webpages.grep 
chmod a+r $SCRIPT_DIR/LongTail-exclude-IPs-httpd.grep
chmod a+r $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep
chmod a+rx $SCRIPT_DIR/LongTail.sh
chmod a+rx $SCRIPT_DIR/LongTail_make_daily_attacks_chart.pl
chmod a+rx $SCRIPT_DIR/LongTail_make_graph.php
chmod a+rx $SCRIPT_DIR/LongTail_make_dashboard_graph.php
chmod a+rx $SCRIPT_DIR/translate_country_codes.sed
chmod a+rx $SCRIPT_DIR/translate_country_codes.sed.orig
chmod a+rx $SCRIPT_DIR/whois.pl
chmod a+r $HTML_DIR/index.shtml 
chown $OWNER $HTML_DIR/index.shtml 
chmod a+r $HTML_DIR/index-long.shtml 
chown $OWNER $HTML_DIR/index-long.shtml 
chmod a+r $HTML_DIR/index-historical.shtml
chown $OWNER $HTML_DIR/index-historical.shtml 
chmod a+r $HTML_DIR/graphics.shtml
chown $OWNER $HTML_DIR/graphics.shtml 
chmod a+r $HTML_DIR/graphics.shtml
chown $OWNER $HTML_DIR/graphics.shtml 

chmod a+r $HTML_DIR/LongTail.css
chown $OWNER $HTML_DIR/LongTail.css 
chmod a+r $HTML_DIR/header.html
chown $OWNER $HTML_DIR/header.html
chmod a+r $HTML_DIR/footer.html
chown $OWNER $HTML_DIR/footer.html

touch $SCRIPT_DIR/Longtail-ssh-local-reports
touch $SCRIPT_DIR/Longtail-httpd-local-reports

#
# Make a default file THISYEAR/THISMONTH/TODAY/current-attack-count.data
# To clear a divide by 0 error that shows up on the fist day running it.


YEAR=`date +%Y`
MONTH=`date +%m`
DAY=`date +%d`

mkdir -p $HTML_DIR/historical/$YEAR/$MONTH/$DAY
echo "0" > $HTML_DIR/historical/$YEAR/$MONTH/$DAY/current-attack-count.data
chown -R $OWNER $HTML_DIR/historical
chmod a+rx $HTML_DIR $HTML_DIR/historical $HTML_DIR/historical/$YEAR $HTML_DIR/historical/$YEAR/$MONTH $HTML_DIR/historical/$YEAR/$MONTH/$DAY $HTML_DIR/historical/$YEAR/$MONTH/$DAY/current-attack-count.data 

#
# Check for required software here
#
#Check for required software here
#
for i in perl php find sort uniq grep egrep cat tac unzip bzcat zcat whois ; do
	echo -n "Checking for $i...  "
	which $i >/dev/null 
	if [ $? -eq 0 ]; then
		echo "$i found"
	else
		echo "$i not found, you need to install this"
	fi
done
echo "You should probably run the following command to install all the php "
echo "required for graphing"
echo "       yum install php php-common php-cli php-xml php-pear php-pdo php-gd"
echo ""
echo "And download jpgraph from http://jpgraph.net/download/ installed into "
echo "/usr/local/php/jpgraph.  (Don't forget to edit the include line in "
echo "/etc/php.ini to reference /usr/local/php)."

