#!/usr/bin/env bash
#
# This script starts storescp to receive and store DICOM files, and then initiate processing
#

# Get the path to the directory of this script
incomingDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source setup.brainstem.bash
. "$incomingDir/../setup.brainstem.bash"

# Check if directory for incoming data exists (should be a tmpfs mount by Docker),
# otherwise create it
if [ ! -d "$incomingDir/data/" ]; then mkdir "$incomingDir/data/"; fi

# Run storescp to receive DICOM files, store them and run a script once a study has been completely received
${storescp} \
  --verbose \
	--aetitle $calling_aetitle \
	--output-directory "$incomingDir/data/" \
	--sort-conc-studies bia \
	--filename-extension '.dcm' \
	--exec-on-eostudy "$incomingDir/../received/received.bash #p" \
	--eostudy-timeout 30 \
	${listening_port}
