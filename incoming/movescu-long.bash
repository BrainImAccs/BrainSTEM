#!/usr/bin/env bash
#
# This script needs a Series Instance UID as argument, then queries the PACS to send that study
# to the already running storescp (see incoming-long.bash).
#
# Call the script with the 0020,000e Series Instance UID as argument, e.g.
#   ./movescu-long.bash 1.2.34.5.6789.0.1.2.34567.89012345678901234567890123456
#

# Check if an argument was supplied
if [ $# -eq 0 ]; then
  echo "Please supply the 0020,000e Series Instance UID to retrieve as an argument, e.g."
  echo "  $0 1.2.34.5.6789.0.1.2.34567.89012345678901234567890123456"
  exit 1
fi

# Check for a valid Series Instance UID (numbers and dots allowed, only)
if [[ ! $1 =~ ^[0-9\.]+$ ]]; then
  echo "The argument doesn't seem to be a Series Instance UID. Please call the script as follows: "
  echo "  $0 1.2.34.5.6789.0.1.2.34567.89012345678901234567890123456"
  exit 1
fi

# Get the path to the directory of this script
incomingDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# seriesUID to retrieve
seriesUID=$1

# Source setup.brainstem.bash
. "$incomingDir/../setup.brainstem.bash"

# Run movescu to instruct the PACS to send the series with to the already running storescp
${movescu} \
  --verbose \
  --aetitle ${calling_aetitle_long} \
  --call ${movescu_called_aetitle_peer} \
  --move ${calling_aetitle_long} \
  --key "0008,0052=SERIES" \
  --key "0020,000e=${seriesUID}" \
  ${movescu_peer} ${movescu_port} 1>>"$incomingDir/movescu-long.log" 2>&1
