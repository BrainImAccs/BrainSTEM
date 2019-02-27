# Contrib scripts

## movescu_access_log_tail.bash: movescu example

This script is a very simple example to tail nginx's `access.log`, extract Series Instance UIDs from the log and use those to call `movescu-short.bash`, which then initiates queueing and processing.

This was used for testing purposes. A script in our PACS sent eligible Series Instance UIDs as a HTTP GET request to our server (which was running a nginx webserver)

The HTTP GET request was sent to `/vbtools/qr.php?seriesUid=<seriesUID>&stationName=<stationName>`. `qr.php` is just an empty file (not a PHP script), so that nginx would respond with a HTTP code 200.

You will need to add an entry similar to the following to your sudoers file:
```
vb      ALL=(www-data:adm) NOPASSWD: /usr/bin/tail -F -n0 /var/log/nginx/access.log
```

The script can be called as `./movescu_access_log_tail.bash &`
