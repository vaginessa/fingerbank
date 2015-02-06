#!/bin/bash

# the url always change it so we find it though the page
ANDROID_PDF=$(curl https://support.google.com/googleplay/answer/1727131?hl=en-CA | egrep -o "//storage.googleapis.com/support-kms-prod/.*\">PDF" | egrep -o //storage.googleapis.com/support-kms-prod/.*\" | sed -e 's/\"//')
ANDROID_PDF="https:$ANDROID_PDF"
echo $ANDROID_PDF

# get the android models pdf and convert it
curl $ANDROID_PDF > tmp/android_devices.pdf
pdftotext -layout tmp/android_devices.pdf

# pdf to text generates ^L characters. we remove them
sed 's///g' tmp/android_devices.txt > tmp/android_devices_clean.txt

# we launch the importation job
echo "Starting Android import job"
RAILS_ENV=production bundle exec rake import:android_models[tmp/android_devices_clean.txt]

# refresh cfnetwork discoverers
curl http://user-agents.me/cfnetwork-version-list > tmp/cfnetwork-version-list.html
# we discover the cfnetwork
echo "Starting CFNETWORK import job"
RAILS_ENV=production bundle exec rake import:cfnetwork[tmp/cfnetwork-version-list.html]

# discovery jobs
echo "Starting Windows phone discovery job"
RAILS_ENV=production bundle exec rake import:discover_windows_phone
echo "Starting BB phone discovery job"
RAILS_ENV=production bundle exec rake import:discover_blackberry_models

# merge the stats that were collected (2 days worth)
echo "Starting merge with stats"
RAILS_ENV=production bundle exec rake import:merge_stats[tmp/stats.sqlite,2]

# rebuild the discoverers cache from scratch
RAILS_ENV=production bundle exec rake fbcache:clear_discoverers 
echo "Starting discoverers cache build"
RAILS_ENV=production bundle exec rake fbcache:build_discoverers 

# reevaluate every combination
echo "Starting the reprocessing of all the combinations"
RAILS_ENV=production bundle exec rake db:sort_combination

# find the mobile + tablets in what we have
echo "Finding the mobiles + tablets"
RAILS_ENV=production bundle exec rake import:detect_device_metadata

# refresh the stats page on the website
echo "Refreshing the stats"
RAILS_ENV=production bundle exec rake fbcache:refresh_stats

touch tmp/restart.txt
