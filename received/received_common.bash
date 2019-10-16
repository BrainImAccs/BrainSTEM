#!/usr/bin/env bash
#
# This script contains common functions for received-* scripts.
#


function dcmSort {
  # Incoming directory containing (potentially unsorted) DICOM files
  local incoming="${1}"

  # Target directory after sorting and meta data generation
  local parentDir="${2}"

  # Initiate loop variables
  local currentSeriesUID=""
  local jobDir=""

  # 0008,0060 Modality
  # 0020,0011 Series Number
  # 0020,000e Series Instance UID
  # 0008,0021 Series Date
  # 0008,0031 Series Time
  # 0020,000d Study Instance UID

  # Dump filename, modality, series number and series UID of each DICOM file, to be used in a loop
  # Sort the output by the fourth column, which is the series UID and run a while loop on the output
  ${dcmdump} \
    --print-all \
    --print-filename \
    --search 0008,0060 \
    --search 0020,0011 \
    --search 0020,000e \
    --search 0008,0021 \
    --search 0008,0031 \
    --search 0020,000d \
    "$incoming"/* | \
      sed -e 's/\(([0-9a-f]\{4\},[0-9a-f]\{4\})\) [A-Z][A-Z] \[\(.*\)\].*#.*/\2/' | \
      sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/;/g' | \
      sed -e "s/# dcmdump ([0-9\/]\+): /\n/g" | tail -n +2 | sort -t';' -k4,4 | while IFS=";" read dcm modality seriesNo seriesUID seriesDate seriesTime studyUID rest; do
        # Ignore any Presentation State (PR) modality DICOM files
        if [[ "$modality" == "PR" ]]; then continue; fi

        # If a new series UID appears, start storing the files into a new subdirectory
        if [[ "$seriesUID" != "$currentSeriesUID" ]]; then
          jobDir="${parentDir}/${seriesNo}-${seriesUID}"

          # Create the subdirectory and add it to a file, which will later be concatted to the global queue
          mkdir -p "${jobDir}" && \
          echo ${jobDir} >> "${parentDir}/toqueue"

          # Add information to dcm-dir-meta-index
          echo "${modality};${seriesNo};${seriesDate};${seriesTime};${seriesUID};${studyUID};./${seriesNo}-${seriesUID}" >> "${parentDir}/dcm-dir-meta-index"
        fi

        # Move the file to the respective subdirectory
        mv "${dcm}" "${jobDir}/"

        # Add information to dcm-meta-index
        echo "${modality};${seriesNo};${seriesDate};${seriesTime};${seriesUID};${studyUID};./${seriesNo}-${seriesUID}/$(basename ${dcm})" >> "${parentDir}/dcm-meta-index"

        # Update currentSeriesUID, so that the next iteration of the loop can check for a new series
        currentSeriesUID=$seriesUID
      done
}
