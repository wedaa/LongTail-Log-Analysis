#!/bin/sh

#called as LongTail_rebuild_month_dashboard_charts.sh <PATH>/historical/<YEAR>/<MONTH>
#For example: LongTail_rebuild_month_dashboard_charts.sh /var/www/html/historical/2015/04 

for dir in $1/* ; do
	if [ -d $dir ] ; then
		echo "calling /usr/local/etc/LongTail_make_historical_dashboard_charts.pl $dir"
		/usr/local/etc/LongTail_make_historical_dashboard_charts.pl $dir
	fi
done
