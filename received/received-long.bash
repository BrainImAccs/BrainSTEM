#!/usr/bin/env bash
#
# This script is run from incoming-long.bash, as soon as a study has been completely received. Since more than
# a single series might have been sent, this scripts breaks up the DICOM files per series into separate sub-
# directories and submits a job per series.
# 

set -x

# incoming-long.bash calls this script with the path to the received files as first argument
incoming=$1

# Get the path to the directory of this script
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source setup.brainstem.bash
. "${__dir}/../setup.brainstem.bash"

# Submit to the following queue
queue="long"
queueDir="${__dir}/${queue}"
parentDir="${queueDir}/"$(date "+%Y%m%d-%H%M%S")

# Source the common functions, if necessary
if [[ ! "$(type -t dcmSort)" = "function" ]]; then
  source "${__dir}/received_common.bash"
fi

# Sort the DICOM files from the incoming directory into the target (parent) directory and generate some metadata
dcmSort "${incoming}" "${parentDir}"

# Remove the old (now empty) directory and concat the temporary queue file to the global queue, to be executed
rm -rf "$incoming" && \
cat "${parentDir}/toqueue" >> "${queueDir}/queue"
