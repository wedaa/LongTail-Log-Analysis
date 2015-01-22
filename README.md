README for LongTail Log Analysis.
==============

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

New SSHD Installation
--------------
Download a copy of openssh from http://www.openssh.com/portable.html#ftp
Untar the file and modify auth-passwd.c to add the 
following line to the auth_password function(See the
included auth-passwd.c file for exact placing) :
 logit("PassLog: Username: %s Password: %s", authctxt->user, password);

Then configure, make, and install openssh on your server.
I assume since you're interested in HoneyPots, you 
know your OS well enough to do this.

You can also run a second sshd on your system on a 
different port.  BUT...  To be able to tell which 
sshd is on which port, you should eit auth-passwd.c 
again, and instead of "PassLog", use "Pass2222Log.
Note that the port number is in the middle of the 
word PassLog.  This is because the search string
LongTail uses in "PassLog"  Making the string 
"Pass2222Log" makes it possible to search for
ssh attempts to the different ports.

LongTail Installation
--------------
Edit LongTail.sh for the locations of your 
/var/log/messages and /var/log/httpd/access_log files.

Edit LongTail.sh for the location of your 
/honey directory (or whatever you call the directory
you want your reports to go to.

Edit Longtail.sh for OBFUSCATE_IP_ADDRESSES and OBFUSCATE_URLS. 
If you are copying your reports to a public site you might 
want to do this.

Edit LongTail-exclude-accounts.grep to
add your valid local accounts.  This will exclude these
accounts from your reports.  (You wouldn't want to have
your password or account name showing up in your reports,
now would you?)

Edit LongTail-exclude-IPs.grep to
add your local IP addresses.  This will exclude these
IPs from your reports.  (You wouldn't want to have
your personal or work IPs exposed in your reports,
now would you?)

Edit LongTail-exclude-webpages.grep to add any local
webpages you don't want in your LongTail reports.

Edit install.sh for SCRIPT_DIR, HTML_DIR, and OWNER.
You also need to comment out the "exit" command, which 
is there to make sure you edit the install.sh script.

Run ./install.sh to install everything.

Run LongTail by hand as the account you want it to run
as to make sure it works.  (And that it can write to 
the /honey directory.)

After you have run LongTail for "a while", you may wish
to add your own special reports.  Those reports should
be included in two special files that will NOT be 
overwritten by install.sh

These scripts are:
	$SCRIPT_DIR/Longtail-ssh-local-reports
	$SCRIPT_DIR/Longtail-httpd-local-reports


Add a crontab entry like this one:
59 * * * * /usr/local/etc/LongTail >> /tmp/LongTail.out 2>> /tmp/LongTail.out

