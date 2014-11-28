
# the url always change it so we find it though the page
ANDROID_PDF=$(curl https://support.google.com/googleplay/answer/1727131?hl=en-CA | egrep -o "//storage.googleapis.com/support-kms-prod/.*\">\(PDF\)" | egrep -o //storage.googleapis.com/support-kms-prod/.*\" | sed -e 's/\"//')
ANDROID_PDF="https:$ANDROID_PDF"
echo $ANDROID_PDF

# get the android models pdf and convert it
curl $ANDROID_PDF > tmp/android_devices.pdf
pdftotext -layout tmp/android_devices.pdf

# pdf to text generates ^L characters. we remove them
sed 's///g' tmp/android_devices.txt > tmp/android_devices_clean.txt

# we launch the importation job
RAILS_ENV=production rake import:android_models[tmp/android_devices_clean.txt]

# refresh cfnetwork discoverers
curl http://user-agents.me/cfnetwork-version-list > tmp/cfnetwork-version-list.html
# we discover the cfnetwork
RAILS_ENV=production rake import:cfnetwork

# discovery jobs
RAILS_ENV=production rake import:discover_windows_phone
RAILS_ENV=production rake import:discover_blackberry_models

# merge the stats that were collected (2 days worth)
RAILS_ENV=production rake import:merge_stats[tmp/stats.sqlite,2]

# rebuild the discoverers cache from scratch
RAILS_ENV=production rake fbcache:clear_discoverers 
RAILS_ENV=production rake fbcache:build_discoverers 


# reevaluate every combination
RAILS_ENV=production rake db:sort_combination

# refresh the stats page on the website
RAILS_ENV=production rake fbcache:refresh_stats

touch tmp/restart.txt
