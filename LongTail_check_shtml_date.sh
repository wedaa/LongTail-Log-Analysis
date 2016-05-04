#!/bin/sh

# Eric Wedaa
# May 4, 2016
# This script runs at 6:00 am via cron to make sure all files have
# been updated recently.  This is to catch occasions when a cron
# entry was commented out during testing, and not re-enabled.
# crontab entry is
# 6 6 * * * /usr/local/etc/LongTail_check_shtml_date.sh |mailx -s"Longtail old file" test@example.com 

#funtion arguments -> filename to comapre against curr time
function comparedate() {
if [ ! -f $1 ]; then
  echo "file $1 does not exist"
	exit 1
fi
MAXAGE=$(bc <<< '48*60*60') # seconds in 48 hours
# file age in seconds = current_time - file_modification_time.
FILEAGE=$(($(date +%s) - $(stat -c '%Y' "$1")))
test $FILEAGE -lt $MAXAGE && {
#    echo "$1 is less than 48 hours old."
    return 0
}
echo "$1 is older than 48 hours"
return 1
}


honey_files="dashboard_passwords.png
 dashboard_usernames.png
 dashboard_ips.png
 dashboard_number_of_attacks.png
 dashboard_ips.data
 dashboard_number_of_attacks.data
 dashboard_passwords.data
 dashboard_usernames.data
 historical_ssh_probes.shtml
 historical_ssh_probes_sorted.shtml
 todays_ssh_probes_sorted.shtml
 index-long.shtml
 index.shtml
 password_analysis_todays_passwords.shtml
 blacklist_efficiency.shtml
 attacks_by_day.shtml
 current-top-20-root-passwords.map
 current-top-20-root-passwords.png
 current-top-20-non-root-passwords.map
 current-top-20-non-root-passwords.png
 current-top-20-non-root-accounts-real.map
 current-top-20-non-root-accounts-real.png
 current-top-20-non-root-accounts.map
 current-top-20-non-root-accounts.png
 current-top-20-admin-passwords.map
 current-top-20-admin-passwords.png
 date_updated.txt
 current-attack-count.data
 current-raw-data.gz
 current-ssh-attacks-by-time-of-day.shtml
 current-top-20-non-root-pairs.shtml
 current-non-root-pairs.shtml
 current-account-password-pairs.data.gz
 current-top-20-attacks-by-country.shtml
 current-attacks-by-country.shtml
 current-top-20-ip-addresses.shtml
 current-ip-addresses.shtml
 current-map.html
 current-ip-addresses.txt
 current-top-20-non-root-accounts-real.data
 current-top-20-non-root-accounts.data
 current-top-20-non-root-accounts.shtml
 current-non-root-accounts.shtml
 current-top-20-non-root-accounts-real.shtml
 current-top-20-non-root-passwords.data
 current-non-root-passwords.shtml
 current-top-20-non-root-passwords.shtml
 current-top-20-admin-passwords.data
 current-admin-passwords.shtml
 current-top-20-admin-passwords.shtml
 current-top-20-root-passwords.data
 current-top-20-root-passwords.shtml
 current-root-passwords.shtml.gz
 more_statistics_all.shtml
 statistics_all.shtml
 more_statistics.shtml
 statistics.shtml
 todays_honeypots.shtml
 todays-honeypots.txt.count
 todays-honeypots.txt
 todays-uniq-ips.shtml
 todays-uniq-ips.txt
 todays_ips.count
 todays_ips
 todays-uniq-username.shtml
 todays-uniq-username.txt
 todays_username.count
 todays_username
 todays-uniq-passwords.shtml
 todays-uniq-passwords.txt
 todays_password.count
 todays_passwords
 graphics.shtml
 index-long-map.shtml
 index-map.shtml
 clients.data
 ibm_accounts.txt
 IPs_looking_for_passwords-country.shtml
 IPs_looking_for_passwords-last-seen.shtml
 IPs_looking_for_passwords-login-attempts.shtml
 IPs_looking_for_passwords-non-403.shtml
 IPs_looking_for_passwords-pages-requested.shtml
 IPs_looking_for_passwords.shtml
 whois.shtml
 class_c_list.shtml
 class_c_hall_of_shame.shtml
 first_seen_passwords.shtml.gz
 first_seen_usernames.shtml
 password_list_analysis_all_passwords.shtml
 password_analysis_all_passwords.shtml
 2000-longest-passwords.txt
 30_days_imagemap.html
 last-90-days-todays-uniq-passwords-txt-count.map
 last-90-days-todays-uniq-passwords-txt-count.png
 last-7-days-top-20-root-passwords.map
 last-7-days-top-20-root-passwords.png
 last-7-days-top-20-non-root-passwords.map
 last-7-days-top-20-non-root-passwords.png
 last-7-days-top-20-non-root-accounts-real.map
 last-7-days-top-20-non-root-accounts-real.png
 last-7-days-top-20-non-root-accounts.map
 last-7-days-top-20-non-root-accounts.png
 last-7-days-top-20-admin-passwords.map
 last-7-days-top-20-admin-passwords.png
 last-30-days-username-count.map
 last-30-days-username-count.png
 last-30-days-top-20-root-passwords.map
 last-30-days-top-20-root-passwords.png
 last-30-days-top-20-non-root-passwords.map
 last-30-days-top-20-non-root-passwords.png
 last-30-days-top-20-non-root-accounts-real.map
 last-30-days-top-20-non-root-accounts-real.png
 last-30-days-top-20-non-root-accounts.map
 last-30-days-top-20-non-root-accounts.png
 last-30-days-top-20-admin-passwords.map
 last-30-days-top-20-admin-passwords.png
 last-30-days-todays-uniq-passwords-txt-count.map
 last-30-days-todays-uniq-passwords-txt-count.png
 last-30-days-password-count.map
 last-30-days-password-count.png
 last-30-days-ips-count.map
 last-30-days-ips-count.png
 last-30-days-attack-count.png
 historical-top-20-root-passwords.map
 historical-top-20-root-passwords.png
 historical-top-20-non-root-passwords.map
 historical-top-20-non-root-passwords.png
 historical-top-20-non-root-accounts-real.map
 historical-top-20-non-root-accounts-real.png
 historical-top-20-non-root-accounts.map
 historical-top-20-non-root-accounts.png
 historical-top-20-admin-passwords.map
 historical-top-20-admin-passwords.png
 last-30-days-ips-count.data
 last-30-days-username-count.data
 last-30-days-password-count.data
 last-30-days-sshpsycho-2-attack-count.data
 last-30-days-todays-uniq-ips-txt-count.data
 last-30-days-todays-uniq-passwords-txt-count.data
 last-30-days-todays-uniq-usernames-txt-count.data
 last-30-days-attack-count.data
 last-30-days-associates-of-sshpsycho-attack-count.data
 last-30-days-friends-of-sshpsycho-attack-count.data
 last-30-days-sshpsycho-attack-count.data
 historical-ssh-attacks-by-time-of-day.shtml
 historical-top-20-non-root-pairs.shtml
 historical-non-root-pairs.shtml
 historical-top-20-attacks-by-country.shtml
 historical-attacks-by-country.shtml
 historical-top-20-ip-addresses.shtml
 historical-ip-addresses.shtml
 historical-map.html
 historical-ip-addresses.txt
 historical-top-20-non-root-accounts-real.data
 historical-top-20-non-root-accounts.data
 historical-top-20-non-root-accounts.shtml
 historical-non-root-accounts.shtml
 historical-top-20-non-root-accounts-real.shtml
 historical-top-20-non-root-passwords.data
 historical-top-20-non-root-passwords.shtml
 historical-non-root-passwords.shtml
 historical-top-20-admin-passwords.data
 historical-top-20-admin-passwords.shtml
 historical-admin-passwords.shtml
 historical-top-20-root-passwords.data
 historical-top-20-root-passwords.shtml
 historical-root-passwords.shtml.gz
 last-30-days-ssh-attacks-by-time-of-day.shtml
 last-30-days-top-20-non-root-pairs.shtml
 last-30-days-non-root-pairs.shtml
 last-30-days-top-20-attacks-by-country.shtml
 last-30-days-attacks-by-country.shtml
 last-30-days-top-20-ip-addresses.shtml
 last-30-days-ip-addresses.shtml
 last-30-days-map.html
 last-30-days-ip-addresses.txt
 last-30-days-top-20-non-root-accounts-real.data
 last-30-days-top-20-non-root-accounts.data
 last-30-days-top-20-non-root-accounts.shtml
 last-30-days-non-root-accounts.shtml
 last-30-days-top-20-non-root-accounts-real.shtml
 last-30-days-top-20-non-root-passwords.data
 last-30-days-top-20-non-root-passwords.shtml
 last-30-days-non-root-passwords.shtml
 last-30-days-top-20-admin-passwords.data
 last-30-days-top-20-admin-passwords.shtml
 last-30-days-admin-passwords.shtml
 last-30-days-top-20-root-passwords.data
 last-30-days-top-20-root-passwords.shtml
 last-30-days-root-passwords.shtml.gz
 last-7-days-ssh-attacks-by-time-of-day.shtml
 last-7-days-top-20-non-root-pairs.shtml
 last-7-days-non-root-pairs.shtml
 last-7-days-top-20-attacks-by-country.shtml
 last-7-days-attacks-by-country.shtml
 last-7-days-top-20-ip-addresses.shtml
 last-7-days-ip-addresses.shtml
 last-7-days-map.html
 last-7-days-ip-addresses.txt
 last-7-days-top-20-non-root-accounts-real.data
 last-7-days-top-20-non-root-accounts.data
 last-7-days-top-20-non-root-accounts.shtml
 last-7-days-non-root-accounts.shtml
 last-7-days-top-20-non-root-accounts-real.shtml
 last-7-days-top-20-non-root-passwords.data
 last-7-days-top-20-non-root-passwords.shtml
 last-7-days-non-root-passwords.shtml
 last-7-days-top-20-admin-passwords.data
 last-7-days-top-20-admin-passwords.shtml
 last-7-days-admin-passwords.shtml
 last-7-days-top-20-root-passwords.data
 last-7-days-top-20-root-passwords.shtml
 last-7-days-root-passwords.shtml.gz
 all-ips
 all-username
 all-password
 trends-in-accounts.shtml
 trends-in-admin-passwords.shtml
 trends-in-root-passwords.shtml
 trends-in-non-root-passwords.shtml
 root_password.txt
 dictionaries.shtml
 ip_attacks.shtml
 current_attackers_lifespan_ip.shtml
 current_attackers_lifespan_number.shtml
 current_attackers_lifespan_last.shtml
 current_attackers_lifespan_first.shtml
 current_attackers_lifespan_botnet.shtml
 current_attackers_lifespan.shtml
 SSHPsycho.shtml
 attack_patterns_single.shtml
 attack_patterns.shtml"

cd /var/www/html/honey/
for file in $honey_files ; do
#	echo "========"
#	echo $file
#	if test "`find $file -mtime +2`" ; then echo "BAD"; fi
#	if comparedate $file ; then echo "good";else echo "bad" ; fi
	comparedate $file 
done
