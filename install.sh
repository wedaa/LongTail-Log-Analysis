#!/bin/sh

#echo "You need to edit LongTail.sh.  Please see LongTail.sh for details"
#echo ""
#echo "You need to edit this file for SCRIPT_DIR, HTML_DIR, and OWNER"
#echo "And then comment out the exit statement"
#exit

SCRIPT_DIR="/usr/local/etc"    # Where do we put the scripts?
HTML_DIR="/var/www/html/honey" # Where do we put the HTML files?
OWNER="wedaa"                  # What is the owner of the process running LongTail?

cp catall.sh $SCRIPT_DIR
cp ip-to-country $SCRIPT_DIR
cp LongTail.sh $SCRIPT_DIR
cp translate_country_codes.sed $SCRIPT_DIR
cp translate_country_codes.sed.orig $SCRIPT_DIR
cp whois.pl $SCRIPT_DIR
cp index.html $HTML_DIR
cp index-long.html $HTML_DIR
cp index-historical.html $HTML_DIR

if [ ! -e $SCRIPT_DIR/LongTail-exclude-accounts.grep ] ; then
echo "LongTail-exclude-accounts.grep not in $SCRIPT_DIR"
fi

#cp LongTail-exclude-accounts.grep $SCRIPT_DIR
#cp LongTail-exclude-webpages.grep $SCRIPT_DIR
#cp LongTail-exclude-IPs.grep $SCRIPT_DIR


chmod a+rx catall.sh $SCRIPT_DIR/catall.sh
chmod a+rx ip-to-country $SCRIPT_DIR/ip-to-country
chown $OWNER $SCRIPT_DIR/ip-to-country

chmod a+r $SCRIPT_DIR/LongTail-exclude-accounts.grep
chmod a+r $SCRIPT_DIR/LongTail-exclude-webpages.grep 
chmod a+r $SCRIPT_DIR/LongTail-exclude-IPs.grep
chmod a+rx $SCRIPT_DIR/LongTail.sh
chmod a+rx $SCRIPT_DIR/translate_country_codes.sed
chmod a+rx $SCRIPT_DIR/translate_country_codes.sed.orig
chmod a+rx $SCRIPT_DIR/whois.pl
chmod a+r $HTML_DIR/index.html 
chown $OWNER $HTML_DIR/index.html 
chmod a+r $HTML_DIR/index-long.html 
chown $OWNER $HTML_DIR/index-long.html 
chmod a+r $HTML_DIR/index-historical.html
chown $OWNER $HTML_DIR/index-historical.html 

touch $SCRIPT_DIR/Longtail-ssh-local-reports
touch $SCRIPT_DIR/Longtail-httpd-local-reports
