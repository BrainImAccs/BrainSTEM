#!/usr/bin/env bash
#
# This script is a very simple example to tail nginx's access.log, extract Series Instance UIDs from the log
# and use those to call movescu-*.bash, which then initiates queueing and processing.
#
# This was used for testing purposes. A script in our PACS sent eligible Series Instance UIDs as a HTTP GET
# request to our server (which was running a nginx webserver)
#
# The HTTP GET request was sent to /vbtools/qr.php?seriesUid=<seriesUID>&stationName=<stationName>
#   qr.php is just an empty file (not a PHP script), so that nginx would respond with a HTTP code 200.
#
# You will need to add an entry to your sudoers file:
#  vb      ALL=(www-data:adm) NOPASSWD: /usr/bin/tail -F -n0 /var/log/nginx/access.log
#
# The script can be called as ./movescu_access_log_tail.bash &
#

# Path to access.log
accessLog=/var/log/nginx/access.log
# Which user should be used to tail the access log
accessLogUser=www-data

# Get the path to the directory of this script
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "$(date) Start $0" 1>>"${__dir}/movescu_access_log_tail.log" 2>&1

(sudo -u "${accessLogUser}" /usr/bin/tail -F -n0 "${accessLog}") | \
  grep --line-buffered "/vbtools/qr.php?seriesUid=" | \
  while read line; do
    # Extract information from GET parameters.
    # This could have been done before the loop with a single regular expression, but line buffering was causing
    # issues and this was for testing, only.
    stationName=$(echo $line | cut -d" " -f7 | sed -e 's/^\/vbtools\/qr.php?seriesUid=\([0-9\.]\+\)&stationName=\([A-Za-z0-9_-]\+\)$/\2/')
    seriesUID=$(echo $line | cut -d" " -f7 | sed -e 's/^\/vbtools\/qr.php?seriesUid=\([0-9\.]\+\)&stationName=\([A-Za-z0-9_-]\+\)$/\1/')
    echo $(date) $stationName $seriesUID

    # Double-check if the Series Instance UID is valid, otherwise ignore this line
    if [[ ! $seriesUID =~ ^[0-9\.]+$ ]]; then echo "Not a Series Instance UID."; continue; fi
    
    # Call movescu-short.bash with the seriesUID, which sends the study from the PACS to the already running storescp,
    # which then submits the job(s).
    echo "$(date)  Submitting to movescu-short.bash"
    ${__dir}/../incoming/movescu-short.bash $seriesUID
  done 1>>"${__dir}/movescu_access_log_tail.log" 2>&1
