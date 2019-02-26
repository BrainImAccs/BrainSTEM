#!/usr/bin/env bash
#
# This script starts storescp to receive and store DICOM files, and then initiate processing
#

# Get the path to the directory of this script
incomingDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source setup.brainstem.bash
. "$incomingDir/../setup.brainstem.bash"

# Run storescp to receive DICOM files, store them and run a script once a study has been completely received
${storescp} \
  --verbose \
	--aetitle $calling_aetitle_short \
	--output-directory "$incomingDir/short/" \
	--sort-conc-studies vb \
	--filename-extension '.dcm' \
	--exec-on-eostudy "$incomingDir/../received/received-short.bash #p" \
	--eostudy-timeout 30 \
	${listening_port_short} 1>"$incomingDir/short.log" 2>&1 &
