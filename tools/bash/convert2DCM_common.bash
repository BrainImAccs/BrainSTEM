#!/usr/bin/env bash
#
# This script contains common functions for scripts to convert NIfTI or image files back to DICOM
#

# Function to get the accession number from DICOM (or handle non-existant accession numbers)
function getAccNo {
  # Reference DICOM file (to copy DICOM values from)
  local ref_dcm="${1}"

  # Get accession number from DICOM reference file
  local acc_no=$(getDCMTag "${ref_dcm}" "0008,0050" "n")

  # If there is no accession number, generate a random one using generateUID
  if [[ $acc_no == "NOT_FOUND_IN_DICOM_HEADER" ]]; then
    acc_no=$(generateUID)
  fi

  # In our local setup, we have to replace the last two positions of the accession number in order
  # to route the resulting image to the research PACS. See setup.brainstem.sh
  if [[ $replace_acc_no_last_two != "" ]]; then
    acc_no=$(echo $acc_no | sed -e "s/[a-zA-Z0-9]\{2\}$/${replace_acc_no_last_two}/")
  fi
  
  echo ${acc_no}
}

# Function to source common functions for x2DCM functions
function sourceFunctions2DCM {
  # Source the getDCMTag function, if necessary
  if [[ ! "$(type -t getDCMTag)" = "function" ]]; then
    source "${__dir}/../../tools/bash/getDCMTag.bash"
  fi
  # Source the generateUID function, if necessary
  if [[ ! "$(type -t generateUID)" = "function" ]]; then
    local __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${__dir}/../../tools/bash/generateUID.bash"
  fi
}

# Function to set Series and Instance UIDs
function setSeriesAndInstanceUID {
  # Directory containing the DICOM file to modify
  local dcm_dir="${1}"

  # Generate unique Series Instance UID
  local seriesUID=$(generateUID)

  # Set the Media Storage SOP Instance UID and SOP Instance UID
  # NB: Modifying 0008,0018 will automatically modify 0002,0003, as well
  info "  Setting Series Instance UID to ${seriesUID}"
  info "  Setting Media Storage SOP Instance UID and SOP Instance UID"
  ${dcmftest} "${dcm_dir}/"* | \
      grep -E "^yes:" | \
      while read bool dcm; do
        local instanceUID=$(generateUID)
        "${dcmodify}" \
          --no-backup \
          --insert "(0020,000E)"="${seriesUID}" \
          --insert "(0008,0018)"="${instanceUID}" \
          "${dcm}" || error "dcmodify to set UID failed"
  done || error "Setting UIDs failed"
}
