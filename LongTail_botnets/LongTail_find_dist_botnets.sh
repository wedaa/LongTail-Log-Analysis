#!/bin/sh
cd /usr/local/etc/bots
cat `ls |egrep -v \.sh\|\.pl\|backup\|2015` > /tmp/LongTail_bots.$$

grep `date +%Y-%m-%d` /var/log/messages |grep IP: |grep -vf /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses |grep -vf /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses |egrep -v 222.186.15.36\|202.188.220.133\|122.226.100.59 >/tmp/LongTail_find_distributed_bots.$$

grep -vf /tmp/LongTail_bots.$$ /tmp/LongTail_find_distributed_bots.$$

rm /tmp/LongTail_find_distributed_bots.$$
rm /tmp/LongTail_bots.$$
