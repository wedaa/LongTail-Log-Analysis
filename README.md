README for LongTail Log Analysis.
==============

WARNING
--------------
If you manage to stumble across this at GitHub, this is
not ready to be released.  I'M STILL WORKING ON IT.  OTOH,
I'm close enough to actually be putting it up here so that
I can test the install procedure on a different server 
than the one I'm developing on.

If you're that interested, drop me an email to wedaa@wedaa.com

Licensing
--------------
LongTail is a messages and access_log analyzer

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
the ssh attacks against your server.  LongTail pre-supposes 
that you have compiled your own openssh daemon as described 
below.

LongTail also analyzes your /var/log/httpd/access_log files
to analyze the attacks and probes that your webserver is
subject to.

LongTail is for small (1 server)  to medium size (50 servers)
organizations.  If you have a large organization, then you'll 
probably have too much data to be analyzed.  Of course if you
run this on larger installations and it works, please let me
know so I can increase this number.

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

	yum install jwhois
	yum install php php-common php-cli php-xml php-pear php-pdo php-gd
	yum install httpd

Look up the properl EPEL repo at  https://fedoraproject.org/wiki/EPEL/FAQ

	rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
	yum install rpm-build ttmkfdir
	yum install http://sourceforge.net/projects/mscorefonts2/files/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
	cd /usr/share/fonts
	ln -s msttcore truetype 

jpgraph from http://jpgraph.net/download/ installed into /usr/local/php/jpgraph.  

Edit the include line in /etc/php.ini to reference /usr/local/php.

Fix the timezone line in /etc/php.ini to reference your timezone. (I use America/New_York ).

LongTail Installation
--------------
Edit LongTail.sh for the locations of your 
/var/log/messages and /var/log/httpd/access_log files.

Edit LongTail.sh for the location of your 
/honey directory (or whatever you call the directory
you want your reports to go to.

Edit Longtail.sh for the following variables (which are explained
in the script): 

	GRAPHS
	DEBUG
	DO_SSH
	DO_HTTPD
	OBFUSCATE_IP_ADDRESSES
	OBFUSCATE_URLS
	PASSLOG
	PASSLOG2222
	SCRIPT_DIR
	HTML_DIR
	PATH_TO_VAR_LOG
	PATH_TO_VAR_LOG_HTTPD

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
in two special files that will NOT be overwritten by install.sh

These scripts are:

	$SCRIPT_DIR/Longtail-ssh-local-reports

	$SCRIPT_DIR/Longtail-httpd-local-reports


CRON Entry
--------------
You'll need to run this through cron every hour.  PLEASE NOTE
that it starts at the 59 minute mark.  If you want to run this
just once a day, I would advise running it at 11:59 PM, as there
is code that only runs during the 11 PM time frame.

MY crontab entry looks like this one:

	59 * * * * /usr/local/etc/LongTail.sh >> /tmp/LongTail.out 2>> /tmp/LongTail.out

HTTP Configuration 
--------------
You NEED to have Server Side Includes turned on.  This is so 
that all the headers and footers are the same.  Go to 
http://httpd.apache.org/docs/2.4/howto/ssi.html for help.

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

WARNING about running rsyslog
--------------
1) This has only been tested using rsyslog.  Not syslog, not
syslog-ng.

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

WARNING About System Hostnames
--------------

System hostnames (as reported by the hostname command) should NOT be
fully qualified, and MUST NOT include "-" (dash) characters.  I create
files with hostnames in them and use the "." and "-" characters as
delimeters.

KNOWN ISSUES
--------------
1) DONE.  I need to go through each and every webpage and make sure it 
looks "good".

2) I need to fix the X and Y axis labels so they are not buried
with the "tick" information.

3) DONE (See #20)  Does NOT handle spaces at the start or end of 
the passwords properly.

4) DONE: I think this works now, 2015-02-14.  I don't deal with 
blank/empty passwords at all

5) I need to add a chart of password lengths

6) DONE: 2015-03-18.  It would be nice in the "Trends" tables if the first time an entry 
is used that it showed up in a different color.

7) I should make a line chart of attacks per day.

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

18) Need to do the mean, median, mode, range for number of IP addresses
with more than one attempt  (so I filter out the single attempts from
distributed brute force bots).

19) DONE: I'm going to setup a secondary "Consolidation" server to 
consolidate data on.  Too much work otherwise. How do I consolidate 
data from several servers?  I'm leaning towards a secondary reporter 
server using syslog to consolidate data from several servers and 
running LongTail on that server also.

20) Does not properly handle spaces in password for account:password pairs

21) NICE TO HAVE BUT NOT A PRIORITY  Make a pretty graph of countries attacking.

22) NICE TO HAVE BUT NOT A PRIORITY  Make a pretty graph of attacks per day over the last 30 days.

23) NICE TO HAVE BUT NOT A PRIORITY  Make a pretty graph of unique IP addresses per day over the last 30 days.

24) NICE TO HAVE BUT NOT A PRIORITY  Make a chart of IP addresses that attack more than one host.

25) There's a "bug" in the .grep files where a "#" character matches
some of the lines even though the rest of the line does not exist.  This
is due to my not fully understanding how the grep -vf command works.

26) DONE: Need to work on code for the "consolidation" server.

27) KNOWN BUG in LongTail.sh on first run instances
DEBUG this month statistics
cat: 2015/02/day/current-attack-count-data: no such file or directory
Illegal division by zero at -e line 1.
DEBUG this year statistics
Illegal division by zero at -e line 1.
DEBUG ALL  statistics
Illegal division by zero at -e line 1.

28) Need to speed up whois.pl.

29) DONE 2015-03-18.  I need to cleanup all the temp files so that they are deleted, 

30) NEEDS TO BE DONE: I need to make sure temp files are unique.  Unique is important so multiple 
copies of LongTail can be run at the same time.

31) DONE Added calendar view of attacks per day with links to
the individual day's attacks.

32) I need to start analyzing attacks that come in on port 2222.

33) Can I do telnet honeypots too?

34) I might have a bug in the code for "Median" statistics in the
main line of code.

35) I need to be able to add comments/explanations next to the 
hostnames, particularly in the statistics sections.

36)  I need a --rebuild function that uses the existing .gz files
in the daily folders.

37) I need to analyze "sshd Disconnect" messages that come from hosts
that have not actively tried to login.

38) I need to make sure I disable ssh_keys as logins.

39) I need to analyze ssh_keys as logins.

40) DONE: Added "normalization" of data so I also report full stats
that are from FULL days (24 hours) only.  This way I do not include
totals from partial days or from hosts down a portion of the day
or from systems that are "protected" by IDS or firewalls.

41) I need to automate adding the "protected" data file (The file 
that shows they are protected by a firewall/IDS) into the 
servers daily directories (erhp erhp2).

42) I need to fix the calendar report so the links go someplace real
