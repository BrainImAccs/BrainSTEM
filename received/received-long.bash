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

# Initiate loop variables
currentSeriesUID=""
jobDir=""

# Dump filename, modality, series number and series UID of each DICOM file, to be used in a loop
# Sort the output by the fourth column, which is the series UID and run a while loop on the output
${dcmdump} \
  --print-all \
  --print-filename \
  --search 0008,0060 \
  --search 0020,0011 \
  --search 0020,000e \
  "$incoming"/* | \
    sed -e 's/\(([0-9a-f]\{4\},[0-9a-f]\{4\})\) [A-Z][A-Z] \[\(.*\)\].*#.*/\2/' | \
    sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/§/g' | \
    sed -e "s/# dcmdump ([0-9\/]\+): /\n/g" | tail -n +2 | sort -k4 | while IFS="§" read dcm modality seriesNo seriesUID rest; do
      # Ignore any Presentation State (PR) modality DICOM files
      if [[ "$modality" == "PR" ]]; then continue; fi

      # If a new series UID appears, start storing the files into a new subdirectory
      if [[ "$seriesUID" != "$currentSeriesUID" ]]; then
        jobDir="${parentDir}/${seriesNo}-${seriesUID}"

        # Create the subdirectory and add it to a file, which will later be concatted to the global queue
        mkdir -p "${jobDir}" && \
        echo ${jobDir} >> "${parentDir}/toqueue"
      fi

      # Move the file to the respective subdirectory
      mv "${dcm}" "${jobDir}/"

      # Update currentSeriesUID, so that the next iteration of the loop can check for a new series
      currentSeriesUID=$seriesUID
    done

# Remove the old (now empty) directory and concat the temporary queue file to the global queue, to be executed
rm -rf "$incoming" && \
cat "${parentDir}/toqueue" >> "${queueDir}/queue"
