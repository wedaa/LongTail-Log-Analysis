#!/bin/sh

echo "You need to edit LongTail.sh.  Please see LongTail.sh for details"
echo ""
echo "You need to edit this file for OWNER."
echo ""
echo "And then comment out the exit statement"

exit

OWNER="wedaa" # What is the owner of the process running LongTail?

# DO NOT EDIT BELOW THIS LINE
# I'm sorry, there is still stuff hard-coded in the programs
# that reference these locations.

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

echo ""
echo "#############################################################"
echo "Checking for OS"
echo ""
RHEL=0

if [ -e /etc/redhat-release ] ; then
	echo "This seems to be a RedHat based system"
	RHEL=1
fi
if [ -e /etc/fedora-release ] ; then
	echo "This seems to be a RedHat/Fedora based system"
	RHEL=1
fi
if [ -e /etc/centos-release ] ; then
	echo "This seems to be a RedHat/Centos based system"
	RHEL=1
fi
echo ""
echo ""
echo "#############################################################"
echo "Checking for which command"
echo ""

which ls >/dev/null 2>&1
LAST=$?
if [ $LAST -ne 0 ] ; then
	echo ""
	echo "'which' command not found, can't continue"
	echo "If this is a RedHat based system, please try"
	echo "   yum install which"
	echo "Then run this program again"
	echo ""
	exit
fi

#echo ""
#HONEYPOT="x"
#while [ $HONEYPOT == "x" ] ; do
#	echo ""
#	echo -n "Is this for a Kippo, Cowrie, or LongTail honeypot (K|k|C|c|L|l): "
#	read HONEYPOT
#	case $HONEYPOT in
#	K|k)
#		HONEYPOT="kippo"
#	;;
#	C|c)
#		HONEYPOT="cowrie"
#	;;
#	L|l)
#		HONEYPOT="longtail"
#	;;
#	*)
#	HONEYPOT="x"
#		echo "Invalid honeypot, please try again"
#	;;
#	esac
#done


#
# Check for required software here
#
echo ""
echo "#############################################################"
echo "Checking for required programs now"
echo ""
abort=0
for i in cpan wget gunzip tar perl php find sort uniq grep egrep cat tac unzip bzcat zcat whois ; do
	echo -n "Checking for $i...  "
	which $i >/dev/null
	if [ $? -eq 0 ]; then
		echo "$i found"
	else
		echo "$i not found, you need to install this"
		abort=1
		abort_string="$abort_string $i"
	fi
done

if [ $abort -eq 1 ] ; then
	echo ""
	echo "Please install the required software packages and re-run this script"
	echo "Required programs are $abort_string"
	exit
fi



SCRIPT_DIR="/usr/local/etc"    # Where do we put the scripts?
HTML_DIR="/var/www/html/honey" # Where do we put the HTML files?
HTTP_HTML_DIR="/var/www/html/http" # Where do we put the HTML files?
DICT_DIR="/usr/local/dict"
BOTS_DIR="/usr/local/etc/LongTail_botnets"

echo ""
echo "#############################################################"
echo "Checking to see that $OWNER already exists"
echo ""

echo ""
if id -u "$OWNER" >/dev/null 2>&1; then
	echo "user $OWNER exists, this is good"
else
	echo "user $OWNER does not exist, this is bad"
	echo "Please create the user and re-run this script"
	echo ""
	exit
fi
echo ""
echo "#############################################################"
echo "Making $HTML_DIR/historical/`date +%Y`/`date +%m`/`date +%d` now"
echo ""

mkdir -p $HTML_DIR/historical/`date +%Y`/`date +%m`/`date +%d`
chown $OWNER $HTML_DIR/historical/`date +%Y`/`date +%m`/`date +%d`
chmod a+rx $HTML_DIR/historical/`date +%Y`/`date +%m`/`date +%d`
chown $OWNER $HTML_DIR/historical/`date +%Y`/`date +%m`
chmod a+rx $HTML_DIR/historical/`date +%Y`/`date +%m`
chown $OWNER $HTML_DIR/historical/`date +%Y`
chmod a+rx $HTML_DIR/historical/`date +%Y`
chown $OWNER $HTML_DIR/historical
chmod a+rx $HTML_DIR/historical
chown $OWNER $HTML_DIR
chmod a+rx $HTML_DIR

echo ""
echo "#############################################################"
echo "Making other dirs now"
echo ""

OTHER_DIRS="$HTML_DIR/dashboard /usr/local/etc/black_lists /var/www/html/honey-2222 /var/www/html/honey-22 /var/www/html/telnet /var/www/html/ftp /var/www/html/rlogin  /var/www/html/honey/bots/ /var/www/html/honey/downloads/ /var/www/html/http"

for dir in $SCRIPT_DIR $HTML_DIR  $DICT_DIR $OTHER_DIRS $BOTS_DIR; do
	if [ -e $dir ] ; then
		if [ -d $dir ] ; then
			echo "$dir allready exists, this is a good thing"
		else
			echo "$dir allready exists but is not a directory"
			echo "This is a bad thing, exiting now!"
			exit
		fi
	else
		mkdir -p $dir
		chmod a+rx $dir
	fi
	chown -R $OWNER $dir
done

if [ ! -d $SCRIPT_DIR/LongTail_local_reports ] ; then
	if [ -e $SCRIPT_DIR/LongTail_local_reports ] ; then
		echo "$SCRIPT_DIR/LongTail_local_reports exists, but is not a directory"
		echo "Exiting now"
		exit
	else
		mkdir $SCRIPT_DIR/LongTail_local_reports
		chown $OWNER $SCRIPT_DIR/LongTail_local_reports
		chmod a+rx $OWNER $SCRIPT_DIR/LongTail_local_reports
	fi
fi


echo ""
echo "#############################################################"
echo "Copying bots files now"
echo ""

BOTS_FILES="big_botnet \
LongTail_find_botnet.pl  \
LongTail_get_botnet_stats.pl \
fromage_puant \
new_bots_2  \
pink_roses  \
small_bots \
small_bots_4 \
dead_botnet \
kippo_1  \
new_bots_1  \
new_bots_3  \
pulgas  \
small_bots_3"


for file in $BOTS_FILES ; do
	#echo $file
	cp LongTail_botnets/$file $BOTS_DIR
	chmod a+r $BOTS_DIR/$file
	chown $OWNER $BOTS_DIR/$file
done
echo ""
echo "#############################################################"
echo "Copying assorted /usr/local/etc/ ip related files now"
echo ""

ETC_FILES="ip-to-country \
translate_country_codes.sed \
translate_country_codes \
LongTail-exclude-accounts.grep \
LongTail-exclude-webpages.grep  \
LongTail-exclude-IPs-httpd.grep \
LongTail-exclude-IPs-ssh.grep \
LongTail_friends_of_sshPsycho_IP_addresses \
LongTail_sshPsycho_2_IP_addresses \
LongTail_associates_of_sshPsycho_IP_addresses \
LongTail_sshPsycho_IP_addresses"


for file in $ETC_FILES ; do
#	echo $file
	cp $file $SCRIPT_DIR
	chmod a+r $SCRIPT_DIR/$file
	chown $OWNER $SCRIPT_DIR/$file
done

echo ""
echo "#############################################################"
echo "Copying assorted /usr/local/etc/ programs now"
echo ""
PROGRAMS=" LongTail_rebuild_dashboard_index.pl \
LongTail_find_badguys_looking_for_passwords.sh \
LongTail_send_access_to_syslog.pl \
LongTail_make_map.pl \
LongTail_dashboard.pl \
LongTail_import_Kippo_to_LongTail.pl \
LongTail_rebuild_last_month_dashboard_charts.sh \
LongTail_rebuild_dashboard_index.pl \
LongTail_make_dashboard_graph.php \
LongTail_rebuild_month_dashboard_charts.sh \
LongTail_make_historical_dashboard_charts.pl \
LongTail_make_30_days_imagemap.pl \
LongTail_make_top_20_imagemap.pl \
LongTail_password_analysis_part_1.pl \
LongTail_password_analysis_part_2.pl \
LongTail_dashboard.pl \
LongTail_password_analysis.pl \
LongTail_analyze_attacks.pl \
catall.sh \
LongTail_add_country_to_ip.pl \
LongTail.sh \
LongTail_nmap_hosts.sh \
LongTail_make_graph_sshpsycho.php \
LongTail_friends_of_sshPsycho_IP_addresses \
LongTail_sshPsycho_IP_addresses \
LongTail_rebuild_month_dashboard_charts.sh \
LongTail_compare_IP_addresses.pl \
LongTail_make_graph.php \
LongTail_make_historical_dashboard_charts.pl \
LongTail_make_dashboard_graph.php \
LongTail_make_daily_attacks_chart.pl \
LongTail_class_b_hall_of_shame.pl \
LongTail_class_c_hall_of_shame.pl \
LongTail_find_first_password_use.pl \
get_traceroute.sh  \
get_whois.sh \
LongTail_find_ssh_probers.pl \
whois.pl "

for file in $PROGRAMS ; do
	cp $file $SCRIPT_DIR
	chmod a+rx $SCRIPT_DIR/$file
	chown $OWNER $SCRIPT_DIR/$file
done

DONT_OVERWRITE_FILES="LongTail.config \
LongTail-wrapper.sh"
for file in $DONT_OVERWRITE_FILES ; do
	if [ -e $file ] ; then
		echo "$file already exists, not overwriting the existing file"
	else
		cp $file $SCRIPT_DIR
		chmod a+rx $SCRIPT_DIR/$file
		chown $OWNER $SCRIPT_DIR/$file
	fi
done

echo ""
echo "#############################################################"
echo "Copying assorted dictionary files now"
echo ""
DICT_FILES="wordsEn.txt"
for file in $DICT_FILES ; do
	echo $file
	cp $file $DICT_DIR
	chmod a+r $DICT_DIR/$file
	chown $OWNER $DICT_DIR/$file
done

echo ""
echo "#############################################################"
echo "Copying assorted html files now"
echo ""
HTML_FILES="ip_addresses.shtml \
contact_us.shtml \
about_longtail_at_marist.shtml \
EU_privacy.shtml \
how_to_protect_yourself.shtml \
index.shtml \
botnet.shtml \
last-30-days-map.html \
current-map.html \
index-long.shtml \
index-long-map.shtml \
index-map.shtml \
how_to_protect_yourself.shtml \
index-long.shtml \
how_to_protect_yourself.shtml \
about.shtml \
index-historical.shtml \
graphics.shtml \
header.html \
footer.html \
institution.html \
description.html \
notes.shtml \
LongTail.css \
buttons.css \
404.shtml \
attacks_view_restricted.shtml"

for dir in $HTML_DIR $OTHER_DIRS ; do
	for file in $HTML_FILES ; do
		cp $file $dir
		chmod a+r $dir/$file	
		chown $OWNER $dir/$file	
	done
done

echo ""
echo "#############################################################"
echo "Copying assorted html files for http honeypot now"
echo ""
echo "I have not tested this yet!  You should look at the directory with a browser"
HTML_FILES="index-historical_http.shtml graphics_http.shtml index-long-map_http.shtml index-map_http.shtml index-long_http.shtml index_http.shtml "
for file in $HTML_FILES ; do
  echo "Copying $file now"
  dest_file=`echo $file |sed 's/_http//'`
	echo "dest file is $dest_file"
  cp $file $HTTP_HTML_DIR/$dest_file
done



echo ""
echo "#############################################################"
echo "Copying assorted html files for port 2222 tests now"
echo ""
cp honey-2222/* /var/www/html/honey-2222/
chmod a+r /var/www/html/honey-2222/*
chown -R $OWNER /var/www/html/honey-2222/*

echo ""
echo "#############################################################"
echo "Setting up dashboard files"
echo ""
cp dashboard-index.shtml $HTML_DIR/dashboard/index.shtml
cp dashboard-1.shtml $HTML_DIR/dashboard/
cp dashboard.shtml $HTML_DIR/

echo "0" > $HTML_DIR/dashboard/count

for file in $HTML_DIR/dashboard/index.shtml \
	$HTML_DIR/dashboard/dashboard-1.shtml \
	$HTML_DIR/dashboard.shtml \
	$HTML_DIR/dashboard/count ; do
	chown $OWNER $file
	chmod a+r $file
done


echo ""
echo "#############################################################"
echo "Setting up historical data files"
echo ""

YEAR=`date +%Y`
MONTH=`date +%m`
DAY=`date +%d`

mkdir -p $HTML_DIR/historical/$YEAR/$MONTH/$DAY
echo "0" > $HTML_DIR/historical/$YEAR/$MONTH/$DAY/current-attack-count.data
chown -R $OWNER $HTML_DIR/historical
chmod a+rx $HTML_DIR $HTML_DIR/historical $HTML_DIR/historical/$YEAR $HTML_DIR/historical/$YEAR/$MONTH $HTML_DIR/historical/$YEAR/$MONTH/$DAY $HTML_DIR/historical/$YEAR/$MONTH/$DAY/current-attack-count.data
chown $OWNER $HTML_DIR $HTML_DIR/historical $HTML_DIR/historical/$YEAR $HTML_DIR/historical/$YEAR/$MONTH $HTML_DIR/historical/$YEAR/$MONTH/$DAY $HTML_DIR/historical/$YEAR/$MONTH/$DAY/current-attack-count.data

#
# Lets deal with the LongTail_local_reports
#
echo ""
echo "#############################################################"
echo "Copying LongTail_local_reports/* now"
echo ""
cd LongTail_local_reports
cp * $SCRIPT_DIR/LongTail_local_reports
chmod a+rx $SCRIPT_DIR/LongTail_local_reports/*
chown $OWNER $SCRIPT_DIR/LongTail_local_reports/*
cd ..


echo ""
echo "#############################################################"
echo "Installing geolocation public database now"
echo ""

cpan CPAN
cpan Geo::IP
cpan Socket6
mkdir /usr/local/share/GeoIP
mkdir /usr/local/share/GeoIP/backups # Will be used to store older copies of database files
pushd /usr/local/share/GeoIP
wget geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
wget geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
wget http://geolite.maxmind.com/download/geoip/database/GeoIPv6.dat.gz
gunzip -f GeoIP.dat.gz
gunzip -f GeoLiteCity.dat.gz
gunzip -f GeoIPv6.dat.gz
popd


echo ""
echo "#############################################################"
echo "Installing jpgraph now"
echo ""

if [ ! -d /usr/local/php/jpgraph-3.5.0b1 ] ; then
		mkdir -p /usr/local/php
		cp jpgraph-3.5.0b1.tar.gz /usr/local/php
		pushd /usr/local/php
		tar -xf /usr/local/php/jpgraph-3.5.0b1.tar.gz
		chown -R $OWNER /usr/local/php/jpgraph-3.5.0b1
		find /usr/local/php/jpgraph-3.5.0b1 -type d |xargs chmod a+rx
		popd
else
	echo "It appears that /usr/local/php/jpgraph-3.5.0b1 already "
	echo "exists, not installing it again."
fi
echo ""
echo "#############################################################"
echo "Installing fancybox now"
echo ""

if [ ! -d /var/www/html/honey/fancybox ] ; then
#		mkdir -p /var/www/html/honey/fancybox
		unzip fancyapps-fancyBox-v2.1.5-0-ge2248f4.zip 
		mv fancyapps-fancyBox-18d1712/ /var/www/html/honey/fancybox
else
	echo "It appears that /var/www/html/honey/fancybox already "
	echo "exists, not installing it again."
fi

echo ""
echo "#############################################################"
echo ""

echo "You should probably run the following command to install all the php "
echo "required for graphing"
echo "       yum install jwhois php php-devel php-common php-cli php-xml php-pear php-pdo php-gd (RHEL 6)"
echo "            OR"
echo "       yum install whois php php-devel php-common php-cli php-xml php-pear php-pdo php-gd (RHEL 7)"
echo ""
echo "Don't forget to edit the include line in "
echo "/etc/php.ini to reference /usr/local/php."

echo ""
echo "You need to install truetype fonts by hand.  Please see the README for directions"
echo ""
echo ""
echo "#############################################################"
echo ""

echo ""
echo "Please add the entries from sample.crontab to your crontab file"
echo ""

echo ""
echo "#############################################################"
echo ""
echo ""
echo "Please run "
echo "      /usr/local/etc/LongTail.sh "
echo "and"
echo "      /usr/local/etc/LongTail.sh -midnight"
echo "to both test your installation, and to finish creating all the webpages"
echo ""
echo "#############################################################"
echo ""
echo "To copy known botnets from longtail.it.marist.edu, do the"
echo "following two commands:"
echo "    cd /usr/local/etc/LongTail_botnets"
echo "    wget -r --no-parent -nd -N --reject "index.html*"   http://longtail.it.marist.edu/honey/downloads/botnets/"


