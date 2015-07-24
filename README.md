README for LongTail Log Analysis.
==============

WARNING
--------------
LongTail is in a constant state of development.  A stable release
will be available (soon?) at http://www.wedaa.com/eric/software/index.html.  
But it's more fun to download what's "live" at github to get the 
latest features.  Reasonable system administration skills are 
required to run and install this software.

Despite my best intentions, web pages have to live in /var/www/html
and scripts have to live in /usr/local/etc.  I'll fix that after
I fix the last bugs and write some proper documentation.

I am not currently providing wordlists for comparison.  You can 
download your own wordlists from 

	http://packetstormsecurity.com/Crackers/wordlists/page1

You do NOT need wordlists to run LongTail, but it is interesting.
No major functionality depends on them.

Licensing
--------------
LongTail is a /var/log/messages and access_log analyzer

Copyright (C) 2015 Eric Wedaa

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

What LongTail does
--------------
Longtail analyzes your /var/log/messages files to report on 
the ssh attacks against your server.  LongTail helps point out
new hosts doing brute force attacks, new passwords and accounts
being tried, and helps point out "Groups" of attackers that are
sharing the same attack patterns.

LongTail generates 20 graphs per host being monitored to help
boil down the statistics into a more usable form.  The 30 day
graphs are also clickable so that you can investigate a 
particular day's activities.

LongTail pre-supposes that you have compiled your own openssh daemon 
as described below.

LongTail is currently for a single server, and up to 10 servers.  
With 10 active servers the main analysis report program
(LongTail_analyze_attacks.pl) takes over 36 minutes to run at 
night with 13 million records. (This will be improved in
 release 2.0)

LongTail ALSO refers to a statistical distribution where there
are many "Hits" at the left, and tapering down to a "Long Tail"
towards the right.  See http://en.wikipedia.org/wiki/Long_tail
for more details.

New SSHD Installation, The Easy Way
--------------
Make sure you have zlib-devel and openssl-devel installed on your
system (plus make, gcc, etc)

	yum install zlib-devel # For the openssh honeypot
	yum install openssl-devel # For the openssh honeypot
	yum install policycoreutils-python # This gives you semanage

The EASY way: Run install_openssh.sh from the repository.  It
will download openssh, modifiy the appropriate source files,
make and install it into /usr/local/{sbin,etc}, and add startup
lines in /etc/rc.local.

You should run a "real" sshd on some very high 
number port so that you can ssh into your server and not have 
your account and password show up in the log files.  You can 
use your default /etc/ssh/sshd_config file to reset your port 
number.

You also need to run the following selinux commands if you have
selinux installed

	semanage port -a -t ssh_port_t -p tcp 2222
	semanage port -a -t ssh_port_t -p tcp <Whatever your big port # is>
	semanage port -l | grep ssh # Shows ssh ports

New SSHD Installation, The HARDER way
--------------
Download a copy of openssh from http://www.openssh.com/portable.html#ftp

Untar the file and modify auth-passwd.c to add the 
following line to the auth_password function(See the
included auth-passwd.c file for exact placing) :
 logit("PassLog: Username: %s Password: %s", authctxt->user, password);

Then configure, make, and install openssh on your server.  I 
assume since you're interested in HoneyPots, you know your OS 
well enough to do this.

You can also run a second sshd on your system on a different 
port.  BUT...  To be able to tell which sshd is on which port, 
you should eit auth-passwd.c again, and instead of "PassLog", 
use "Pass2222Log.  Note that the port number is in the middle 
of the word PassLog.  This is because the search string LongTail 
uses in "PassLog"  Making the string "Pass2222Log" makes it 
possible to search for ssh attempts to the different ports.

You should run a "real" sshd on some very high 
number port so that you can ssh into your server and not have 
your account and password show up in the log files.  You can 
use your default /etc/ssh/sshd_config file to reset your port 
number.

You also need to run the following selinux commands if you have
selinux installed

	semanage port -a -t ssh_port_t -p tcp 2222
	semanage port -a -t ssh_port_t -p tcp <Whatever your big port # is>
	semanage port -l | grep ssh # Shows ssh ports


LongTail Prerequisites
--------------
LongTail requires other software packages to run.  RHEL, CentOS, Fedora Core commands follow:

	yum install jwhois (RHEL 6) OR yum install whois (RHEL 7)
	yum install php php-common php-cli php-xml php-pear php-pdo php-gd
	yum install httpd

LongTail requires jpgraph and TrueType fonts.  (See next section)

FancyBox notes
--------------
I use FancyBox Version 2.1.5 and it is available for non commercial use
at http://fancyapps.com/fancybox

It should be copied into /var/www/html/honey/fancybox/source

Jpgraph Notes
--------------
jpgraph from http://jpgraph.net/download/ installed into /usr/local/php/jpgraph.  

Edit the include line in /etc/php.ini to reference /usr/local/php.

Fix the timezone line in /etc/php.ini to reference your timezone. (I use America/New_York ).

You will need to install the truetype fonts.  

The following instructions are what I think I used, but are untested as of this writing.)
goto http://www.tecmint.com/how-to-enable-epel-repository-for-rhel-centos-6-5/ for instructions on installing latest epel repos

  wget http://corefonts.sourceforge.net/msttcorefonts-2.0-1.spec
  yum install rpm-build cabextract
  rpmbuild -ba msttcorefonts-2.0-1.spec
  yum localinstall --nogpgcheck <PATH_TO_RPM>/msttcorefonts-2.0-1.noarch.rpm
	ln -s /usr/share/fonts/msttcore /usr/share/fonts/truetype

OR

Look up the properl EPEL repo at  https://fedoraproject.org/wiki/EPEL/FAQ
	rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
  yum install rpm-build cabextract
	yum install rpm-build ttmkfdir
	yum install http://sourceforge.net/projects/mscorefonts2/files/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
	ln -s /usr/share/fonts/msttcore /usr/share/fonts/truetype

LongTail Installation
--------------
Edit LongTail.sh for the locations of your 
/var/log/messages and /var/log/httpd/access_log files.

Please note that LongTail requires a HUGE temporary
directory.  There is a variable in LongTail_analyze_attacks.pl
and LongTail.sh called $TMP_DIRECTORY which you should point
to someplace with lots of disk space.  LongTail breaks at 
10 million records with a /tmp of less than a gigabyte of
disk space.

Edit LongTail.sh for the location of your 
/honey directory (or whatever you call the directory
you want your reports to go to.

Edit Longtail.sh and LongTail.config for site-specific variables 
(which are explained in the files).

Edit LongTail-exclude-accounts.grep to add your valid local 
accounts.  This will exclude these accounts from your reports.  
(You wouldn't want to have your password or account name 
showing up in your reports, now would you?)

Edit LongTail-exclude-IPs-httpd.grep and LongTail-exclude-IPs-ssh.grep 
to add your local IP addresses.  This will exclude these IPs from your 
reports.  (You wouldn't want to have your personal or work IPs exposed 
in your reports, now would you?)

Edit LongTail-exclude-webpages.grep to add any local webpages 
you don't want in your LongTail reports.

Edit LongTail_make_graph.php for the appropriate location of
the jpgraph installation.

Edit install.sh for SCRIPT_DIR, HTML_DIR, and OWNER.  You also 
need to comment out the "exit" command, which is there to make 
sure you edit the install.sh script.

Run ./install.sh to install everything.

Run LongTail by hand as the account you want it to run as to 
make sure it works.  (And that it can write to the /honey 
directory.)

Site Specific Reports
--------------
After you have run LongTail for "a while", you may wish to 
add your own special reports.  Those reports should be included 
in a special file that will NOT be overwritten by install.sh

This scripts is:

	$SCRIPT_DIR/Longtail-ssh-local-reports

CRON Entry
--------------
You'll need to run this through cron every hour.  PLEASE NOTE
that it starts at the 5 minute mark.  If you want to run this
just once a day, I would advise running it at 12:05 AM, as there
is code that only runs during the midnight time frame.

MY crontab entry looks like this one:

	#
	#
	# LongTail stuff
	#
	1 0 * * * /usr/local/etc/LongTail_make_fake_password.sh
	1 1 * * * /usr/local/etc/get_whois.sh > /tmp/get_whois.sh.out
	1 2 * * * /usr/local/etc/LongTail_whois_analysis.pl > /var/www/html/honey/whois.shtml
	10 * * * * /usr/local/etc/LongTail-wrapper.sh  >> /tmp/LongTail.sh.out 2>> /tmp/LongTail.sh.out
	30 * * * * /usr/local/etc/LongTail_find_ssh_probers.pl  >> /tmp/LongTail_find_ssh_probers.pl.out 2>> /tmp/LongTail_find_ssh_probers.pl.out
	45 6,18 * * * /usr/local/etc/LongTail_analyze_attacks.pl  >> /tmp/LongTail_analyze_attacks.pl.out 2>> /tmp/LongTail_analyze_attacks.pl.out
	55 0 * * * /usr/local/etc/LongTail_rebuild_dashboard_index.pl  >> /tmp/LongTail.sh.out 2>> /tmp/LongTail.sh.out
	59 * * * * grep telnet /var/log/messages |grep -v \ sshd > /var/www/html/honey/telnet.data
	1 1 1 * * /usr/local/etc/LongTail_rebuild_last_month_dashboard_charts.sh  >>/tmp/LongTail_rebuild_dash.out
	35 23 * * * /usr/local/etc//LongTail_alerts.pl >>/tmp/LongTail_alerts.pl.out
	30 2 * * * /usr/local/etc/LongTail_botnets/LongTail_get_botnet_stats.pl  > /var/www/html/honey/botnet.shtml 
	5 * * * * grep Attack /var/log/messages |awk '{print $6,$10,$14}' |sort |uniq |sed 's/;//g' >>/var/www/html/honey/clients.data; sort -u /var/www/html/honey/clients.data > /tmp/clients.data; /bin/mv /tmp/clients.data /var/www/html/honey/clients.data
	55 3 * * * /usr/local/etc/LongTail_find_badguys_looking_for_passwords.sh >/var/www/html/honey/IPs_looking_for_passwords.shtml
	#
	# LongTail Dashboard counter
	#
	0,5,10,15,20,25,30,35,40,45,50,55 * * * * /usr/local/etc/LongTail_dashboard.pl >> /tmp/LongTail_dashboard.out



HTTP Configuration 
--------------
You NEED to have Server Side Includes turned on.  This is so 
that all the headers and footers are the same.  Go to 
http://httpd.apache.org/docs/2.4/howto/ssi.html for help.

You should also probably use the HTTP error docs for errors 403 
(Forbidden) and 404 (Not Found).

	ErrorDocument 403 /honey/attacks_view_restricted.shtml
	ErrorDocument 404 /honey/404.shtml


WARNING about reports before you have enough data
--------------
Some of the reports are going to look a little "off" until you
have a few days worth of data.  This is because I am currently
assuming that after a few days, attacks will have come in at
every hour of the day.

Also, historical trends reports will look "off" until you actually
have a few days worth of data to do a trend report on.

These issues will not be fixed anytime soon.

MULTIPLE HOSTS
--------------
LongTail can handle multiple hosts reporting.  To create reports for
just one server, use the following command:

	/usr/local/etc/LongTail.sh <hostname>

where <hostname> is the name of the host as reported in the syslog 
file.

WARNING about jpgraph alignment issues
--------------
Two warnings about jpgraph alignment issues.

ONE) Right now the X and Y axis labels can be overwritten by the
tick marks for the axis.  I am looking into this issue.

TWO) For some reason, the X axis labels show up shifted to the
left on some systems (notably my CentOS 6.5 using the Atomic
PHP repos.  On a vanilla Fedora Core 20 system the labels show
up properly under the appropriate bar.  I am looking into this 
issue.

Running rsyslog
--------------
1) This has only been tested using rsyslog.  Not syslog, not
syslog-ng.  I assume they will work too.

2) If you are also logging to a remote host, and you are using 
a port OTHER than 514, AND you are running selinux, make sure
you remember to run this command on BOTH hosts

	semanage port -a -t syslogd_port_t -p tcp NewPortNumber

3) This is the line I use on my honeypot to report to my consolidation
master:

	auth.* @@#.#.#.#:####

where #.#.#.# is the IP address of the receiving host and #### is the
TCP Port where rsyslog is listening on the receiving host.  This way
we are only sending SSH messages to the remote host, instead of
filling it's logs with ALL the messages from the honeypot.

4) You must use the following line in your honeypot's (and if you are
using a consolidation server's ) rsyslog.conf file.

	$ActionFileDefaultTemplate RSYSLOG_FileFormat

5) Make sure you are using the lines in the rsyslog.conf file to 
enable Reliable syslog reporting.

	$WorkDirectory /var/lib/rsyslog # where to place spool files
	$ActionQueueFileName fwdRule1 # unique name prefix for spool files
	$ActionQueueMaxDiskSpace 1g   # 1gb space limit (use as much as possible)
	$ActionQueueSaveOnShutdown on # save messages to disk on shutdown
	$ActionQueueType LinkedList   # run asynchronously
	$ActionResumeRetryCount -1    # infinite retries if host is down

6) Sometimes data gets lost in transmission between clients and the
consolidation server.  I have no idea why.  I have to figure out a
better way of consolidating messages files between hosts and then
re-running reports against the "Better" data.

WARNING About System Hostnames
--------------

System hostnames (as reported by the hostname command) should NOT be
fully qualified, and MUST NOT include "-" (dash) characters.  I create
files with hostnames in them and use the "." and "-" characters as
delimeters.

Files in the html directory that you should know about
--------------
current-attack-count.data.notfullday : Indicates to the system NOT
to include the count from this day in the normalization statistics.
This file should be in historical/year/month/date AND in
systemname/historical/year/month/date when you are using a 
consolidation server.

header.html: This is the global header and includes the menu bars.
This is where you can add links to each host's reports.

footer.html: This is the global footer

description.html: This describes the host.  It should be in 
/var/www/html/honey AND /var/www/html/honey/HOSTNAME

index.shtml: This is the "main" page.  It should be in
/var/www/html/honey AND /var/www/html/honey/HOSTNAME

index-long.shtml: This shows the historical stats.  It should be in
/var/www/html/honey AND /var/www/html/honey/HOSTNAME

index-historical.shtml: This is the webpage that gets copied into 
the historical directories (for instance, /var/www/html/honey/historical/2015/05/05/)

KNOWN ISSUES THAT HAVE YET TO BE DONE
--------------

2) I need to fix the X and Y axis labels so they are not buried
with the "tick" information. (This can wait till other more important
things are done.)

44) I need to cleanup the Dictionary section.  It's still ugly-ish
and needs to be cleaned up and described better

KNOWN ISSUESAND IMPROVEMENTS FOR RELEASE 1.5
--------------

56) RELEASE 1.5: I need to somehow show slowscans and bot net attacks

60) RELEASE 1.5 (In Progress) I desperately need to optimize the LongTail_analyze_attacks.pl
script since it takes so long to run

63) RELEASE 1.5: Auto-report attacks to the various IP Abuse websites.

67) RELEASE 1.5: Make a  5 minute "This is LongTail" slideshow explaining the 
different features and reports in LongTail.

85) RELEASE 1.5:  Make a "Top 5 LongTail webpages" with a note for new viewers 
to look at it. (Tour)

87) RELEASE 1.5 How do I breakout sshpsycho attacks by host attacked?


KNOWN ISSUES AND IMPROVEMENTS FOR RELEASE 2.0
--------------

21) RELEASE 2: NICE TO HAVE BUT NOT A PRIORITY  Make a pretty graph 
of countries attacking.

24) RELEASE 2:  Make a chart/Graph of IP addresses that attack more than 
one host.

39) RELEASE 2: I need to analyze ssh_keys as logins.

58) RELEASE 2: I need to "googlefy" usernames.

61) RELEASE 2: I need to convert LongTail.sh to LongTail.pl so that it 
runs faster.  Now that I know what I'm looking for, it's time to run it 
in perl so that it runs faster.

62) RELEASE 2: Can I run NMap against the attackers and analyze the results?
(I'll need to edit out the traceroute results).

70) RELEASE 2: Make the minimum and maximum entries clickable in the 
statistics tables.

71) RELEASE 2: Get a telnet honeypot working

72) RELEASE 2: Get a rlogin honeypot working

73) RELEASE 2: Make 90 days graphs of ip addresses, # of attacks, etc.

74) RELEASE 2: Is it worth making IP Addresses include a link to Google
search results too?

75) RELEASE 2: My link to "Blacklisted? (http://www.dnsbl-check.info)" 
should probably go somewhere else, but I'm not sure where.

78) RELEASE 2: Attacks by Country should also show the number of attacks 
by each country.

80) RELEASE 2: LongTail shoul also analyze /var/log/httpd/access_log files
to analyze the attacks and probes that a webserver is
subject to.

81) RELEASE 2: (Maybe) "All" graphs, can I color code the amounts by host?

82) RELEASE 2: Add more IP Address blacklists to my blacklist comparison
chart.

KNOWN ISSUES THAT ARE DONE
--------------
1) DONE.  I need to go through each and every webpage and make sure it 
looks "good".

3) DONE (See #20)  Does NOT handle spaces at the start or end of 
the passwords properly.

4) DONE: I think this works now, 2015-02-14.  I don't deal with 
blank/empty passwords at all

5) DONE: I need to add a chart of password lengths

6) DONE: 2015-03-18.  It would be nice in the "Trends" tables if the first time an entry 
is used that it showed up in a different color.

7) DONE: (Made it a bar chart) I should make a line chart of attacks per day.

8) NOT GOING TO HAPPEN.  I should make a line chart of 
number of attacks for an account per day.  This might be a
little ridiculous though...

9) NOT GOING TO HAPPEN, There are too many passwords and I'd have to 
make this dynamic, and I'd rather not suck up CPU OR make a bazillion
premade graphs.  I should make a line chart of number of uses of 
a password for an account per day.

10) DONE: LongTail_analyze_attacks.pl  I still need to finish my third 
level analysis of brute force attacks, which is the real reason I wrote
LongTail.

11) NOT GOING TO HAPPEN.  Can I "googlefy" my account/password pairs?

12) DONE. I need to fix the graph on non-root accounts to filter out the
root attempts...

13) DONE.  /usr/local/etc/LongTail.config now works. I need to 
break-out the editable fields in LongTail.sh, etc, into a 
separate file.

14) DONE. (It's really just a hostname passed) I need to set up a 
"-f" option so we can run multiple instances.  This is a long 
term goal to aid in analyzing multiple sites while running on the 
same server.

15) DONE (See #14) I need to set it up so it can search only by 
hostname in the messages/access_log files so I can have multiple hosts 
sending data to the server.  This is a long term goal to aid in 
analyzing multiple sites while running on the same server.

16) DONE: Fix password printing for alternate syslog line styles (with and 
without IP address in the line.

17) DONE: Need to do the mean, median, mode, range for number 
of ssh attempts.

18) PROBABLY NOT GOING TO HAPPEN: Need to do the mean, median, mode, 
range for number of IP addresses with more than one attempt  (so I 
filter out the single attempts from distributed brute force bots).

19) DONE: I'm going to setup a secondary "Consolidation" server to 
consolidate data on.  Too much work otherwise. How do I consolidate 
data from several servers?  I'm leaning towards a secondary reporter 
server using syslog to consolidate data from several servers and 
running LongTail on that server also.

20) DONE: (Also fixed everywhere) Does not properly handle spaces in 
password for account:password pairs

22) DONE: Make a pretty graph of attacks per day over the last 30 days.

23) DONE  Make a pretty graph of number of 
unique IP addresses per day over the last 30 days.

25) DONE: (I took the comments out of the files.) There's a "bug" in 
the .grep files where a "#" character matches some of the lines even 
though the rest of the line does not exist.  This is due to my not 
fully understanding how the grep -vf command works.

26) DONE: Need to work on code for the "consolidation" server.

27) KNOWN BUG in LongTail.sh on first run instances
DEBUG this month statistics
cat: 2015/02/day/current-attack-count-data: no such file or directory
Illegal division by zero at -e line 1.
DEBUG this year statistics
Illegal division by zero at -e line 1.
DEBUG ALL  statistics
Illegal division by zero at -e line 1.

28) DONE: (I preload the first 5000 entries into the script) Need 
to speed up whois.pl.

29) DONE 2015-03-18.  I need to cleanup all the temp files so that they are deleted, 

30) NEEDS TO BE DONE: I need to make sure temp files are unique.  
Unique is important so multiple copies of LongTail can be run 
at the same time.

31) DONE Added calendar view of attacks per day with links to
the individual day's attacks.

32) DONE: I need to start analyzing attacks that come in on port 2222.

33) DONE: Yes, use same codes as for port 2222 attacks. Can I do 
telnet honeypots too?

34) DONE: I might have a bug in the code for "Median" statistics in the
main line of code.

35) DONE: I need to be able to add comments/explanations next to the 
hostnames, particularly in the statistics sections.

36) DONE: I need a --rebuild function that uses the existing .gz files
in the daily folders.  LongTail.sh needs to be enable this feature
as I am not going to make a -rebuild flag since I do not want this
to be easy to be done.  It's still dangerous.

37) DONE: RELEASE 2: I need to analyze "sshd Disconnect" messages that come 
from hosts that have not actively tried to login.

38) DONE In sshd_config files. I need to make sure I disable ssh_keys as logins.

40) DONE: Added "normalization" of data so I also report full stats
that are from FULL days (24 hours) only.  This way I do not include
totals from partial days or from hosts down a portion of the day
or from systems that are "protected" by IDS or firewalls.

41) DONE: I need to automate adding the "protected" data file (The file 
that shows they are protected by a firewall/IDS) into the 
servers daily directories (erhp erhp2).

42) DONE: (Bug fix only) I need to fix the calendar report so the 
links go someplace real

43) DONE: I need to analyze telnet probes, now that I have that data being 
logged

45) SOMEWHERE (In either the sshd server or rsyslog) there is a bug which if the password is empty, that the 
line sent to syslog is "...Password:$", instead of "...Password: $"
Please note the missing space at the end of the line is the bug
and now I need to code around it everyplace :-(

46) DONE: Make a chart of the first time a password was seen

47) DONE: Show unique usernames, 

48) DONE: Make a chart of the first time a username was seen.

49) DONE: Show unique IP addresses, 

50) DONE: (Part of ip_attacks.shtml) Make a chart of the first time a IP was seen.

51) NOT GOING TO HAPPEN, I don't want to be "denyhosts".  Make IPs available in 
text only format so people can import them into /etc/hosts.deny or whatever.  If
they really want it they can read the source code to figure out where I hide it.

52) DONE: Fixed "bug" where the first day a hostname is seen that
the 7 day, 30 day, and historical graphs are not made until the next
day.

53) DONE: Added a "dashboard"

54) DONE: Need to figure out how to add horizontal lines to a barchart so that
I can show minimum, average, and maximum lines to my dashboard and to
other charts
( http://www.asial.co.jp/jpgraph/demo/src/Examples/show-example.php?target=plotlineex1.php )

55) DONE In statistics section I need to get stats on # of usernames, passwords
and IP addresses.

57) DONE RELEASE 1.5 I need to break out attacks by hosts so I can see the attacks
that get through the IPS more clearly.

59) CRITICAL: FIXED There's a bug in the "normalization" code for some of the 
statistics webpages.

62) DONE: Cleanup formatting in first seen reports

64) DONE: Can I auto-add a date stamp and website address to my graphics?

65) DONE: Finish my install.sh script

66) DONE ENOUGH: Write documentation about LongTail.  This in constantly in 
progress.  This will be covered in the README and the Tour.

68) WHERE WOULD THEY GO? Not going to happen...  Make the graphs on the 
front page "clickable" to go to a page giving more details.

69) DONE: Figure out how to "re-do" the last months dashboard 
graphics so that the graphs all have the same average, minimum, and 
maximum.

76) DONE: Fix display bug in "Calendar View" of attacks where the first day of
the week doesn't always show up in the right column.

77) DONE: Attacks by Country needs to be reverse sorted.

79) RELEASE 1.5: 30 day Graphics(DONE) should also be image maps so the 
user can click on a column and get more information about that date,
Account, or password.

83)DONE:  Make a "What do I do to protect myself?" webpage.  Include 
links to other sites and documents.

84) DONE:  There's a bug in the image mapping for Top 20 non root 
accounts where it doesn't show root, and then only shows 19 accounts.  
Image mapping shows 20 accounts including root.

86)DONE: CRITICAL:  Add a date include file to the historical web pages so the user knows
where/when they are.

88) DONE: To be "really" added once the tour is done.  Add a cookie so that 
brand new visitors have the option of going to the "Most Important 5 Pages" 
webpage (Tour)

89) FIXED Need to fix the bug in sshPsycho friends and associates that overwrites
existing IP addresses in the lists.

90) DONE: RELEASE 1.5 Record port and agent (from sshd -dddd)
Connection from ::1 port 57427
debug1: Client protocol version 2.0; client software version OpenSSH_6.7

91) DONE: Can we do Kippo logs?
