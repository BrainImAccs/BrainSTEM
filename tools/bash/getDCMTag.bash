#!/usr/bin/env bash
#
# This script simply gets the value of a DICOM tag from a DICOM file, cleans up the result and removes formatting specific to DCMTK
#
# The script returns "NOT_FOUND_IN_DICOM_HEADER", when the tag is not found in the DICOM header.
#

function getDCMTag {
  # The DICOM file to read the values from
  local dcm="${1}"
  # The tag to read
  local tag="${2}"
  # Be verbose during the process (default)
  local verbose="${3:-}"

  # Check if file exists and is a regular file
  if [[ ! -f "${dcm}" ]]; then
    error "  ${dcm} does not exist."
  else
    # Get basename for later use
    dcmBasename=$(basename "${dcm}")
  fi

  # Define temporary variables, get dcmdump result in tempValue
  # - Make sure to get top level tag only by using --prepend and excluding nested tags
  # - Empty tempValue for tags which only contain "(no value available)"
  local value=""
  local tempValue=$(${dcmdump} \
    --convert-to-utf8 \
    --print-all \
    --prepend \
    --no-uid-names \
    --search ${tag} \
    "${dcm}" 2>/dev/null | \
      grep -vE '^.*\)\.\(.* ' | \
      sed -e 's/\(([0-9a-f]\{4\},[0-9a-f]\{4\})\) LO (no value available).*#.*//' \
  )

  # Sometimes UTF-8 decoding fails, then try again without --convert-to-utf8
  if [[ $? -ne 0 ]]; then
    local tempValue=$(${dcmdump} \
      --print-all \
      --prepend \
      --no-uid-names \
      --search ${tag} \
      "${dcm}" | \
        grep -vE '^.*\)\.\(.* ' | \
        sed -e 's/\(([0-9a-f]\{4\},[0-9a-f]\{4\})\) LO (no value available).*#.*//' \
    )
  fi

  # If the length of tempValue is 0, the DICOM file does not contain that tag
  # Exit with code 2 and return an empty string
  if [[ ${#tempValue} -eq 0 ]]; then
    # Print tag, DICOM filename as warning (unless supressed)
    if [[ $verbose != "n" ]]; then
      warning "  (${tag}) of ${dcmBasename} is not set."
    fi

    echo "NOT_FOUND_IN_DICOM_HEADER"
  fi

  # If the value is not empty, continue setting value to the actual value.
  value=$(echo $tempValue | \
    sed \
      -e 's/\(([0-9a-f]\{4\},[0-9a-f]\{4\})\) [A-Z][A-Z] \[\(.*\)\].*#.*/\2/' \
      -e 's/\(([0-9a-f]\{4\},[0-9a-f]\{4\})\) [USH]\+ \(.*\) \+#.*/\2/'
  )

  # Print tag, DICOM filename and tag value to the console
  if [[ $verbose != "n" ]]; then
    info "  (${tag}) of ${dcmBasename} is ${value}."
  fi

  # Echo the cleaned up DICOM tag value as the result of the function
  echo ${value}
}

# Export the function to be used when sourced, but do not allow the script to be called directly
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  export -f getDCMTag
else
  echo "getDCMTag is an internal function and cannot be called directly."
  exit 1
fi
