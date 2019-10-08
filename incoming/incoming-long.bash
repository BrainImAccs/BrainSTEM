#!/usr/bin/env bash
#
# This script starts storescp to receive and store DICOM files, and then initiate processing ("long" queue)
#

# Get the path to the directory of this script
incomingDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source setup.brainstem.bash
. "$incomingDir/../setup.brainstem.bash"

# Run storescp to receive DICOM files, store them and run a script once a study has been completely received
${storescp} \
  --verbose \
	--aetitle $calling_aetitle_long \
	--output-directory "$incomingDir/long/" \
	--sort-conc-studies bia \
	--filename-extension '.dcm' \
	--exec-on-eostudy "$incomingDir/../received/received-long.bash #p" \
	--eostudy-timeout 30 \
	${listening_port_long} 1>"$incomingDir/long.log" 2>&1 &
