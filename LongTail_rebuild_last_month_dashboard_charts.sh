#!/bin/sh
# Just a silly wrapper script :-)
/usr/local/etc/LongTail_rebuild_month_dashboard_charts.sh /var/www/html/honey/historical/`date  +"%Y" --date="1 month ago"`/`date  +"%m" --date="1 month ago"`
