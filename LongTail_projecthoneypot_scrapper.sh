#!/bin/sh

if [ ! -d /usr/local/etc/projecthoneypot ] ; then
	echo "Can not find /usr/local/etc/projecthoneypot, exiting now"
	exit;
fi

cd /usr/local/etc/projecthoneypot

date=`date +%Y-%m-%d`
this_year=`date +%Y`

if [ ! -d $this_year ] ; then
	mkdir $this_year
fi
cd $this_year

# Email harvesters
wget -q -O - http://www.projecthoneypot.org/list_of_ips.php?t=s |grep bnone |sed 's/^..*bnone">//' |sed 's/<..*$//' > harvester.$date
# Spam servers
wget -q -O - http://www.projecthoneypot.org/list_of_ips.php?t=s |grep bnone |sed 's/^..*bnone">//' |sed 's/<..*$//' > spam.$date
# Malicious IPs
wget -q -O - http://www.projecthoneypot.org/list_of_ips.php?t=w |grep bnone |sed 's/^..*bnone">//' |sed 's/<..*$//' > malicious.$date
# Comment Spammers
wget -q -O - http://www.projecthoneypot.org/list_of_ips.php?t=p |grep bnone |sed 's/^..*bnone">//' |sed 's/<..*$//' > comment.$date
# Dictionary Attacker IPs
wget -q -O - http://www.projecthoneypot.org/list_of_ips.php?t=d |grep bnone |sed 's/^..*bnone">//' |sed 's/<..*$//' > dictionary.$date
# Rule Breaker IPs
wget -q -O - http://www.projecthoneypot.org/list_of_ips.php?t=r |grep bnone |sed 's/^..*bnone">//' |sed 's/<..*$//' > rule.$date
# Search engines
wget -q -O - http://www.projecthoneypot.org/list_of_ips.php?t=se |grep bnone |sed 's/^..*bnone">//' |sed 's/<..*$//' > search.$date

for file in harvester spam malicious comment dictionary rule search ; do
	echo $file
	cat $file.$this_year-* |sort |uniq > ../$file
done
