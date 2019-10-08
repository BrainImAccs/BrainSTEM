#!/usr/bin/env bash
#
# This script takes a single reference DICOM file and copies DICOM values from a defined set of DICOM tags
# onto a stack of DICOM files inside a directory
#

function copyDCMTags {
  # Single reference DICOM file
  local ref_dcm="${1}"
  # Directory of DICOM files to copy the DICOM values onto
  local output_dir="${2}"
  # The DICOM tags to be copied, seperated by a space (e.g. "0001,0001 0001,0002 0001,0003")
  local dcm_tags=${3}

  info "  copyDCMTags start"
  info "    LANG=${LANG}"

  # Concat the DICOM tags to be copied and get the values all at once from the reference DICOM file
  "${dcmdump}" \
    --print-all \
    --no-uid-names \
    $(for dcm_tag in ${dcm_tags}; do echo -n " --search $dcm_tag"; done) \
    "${ref_dcm}" | \
      # Use regular expressions to clean up the data and remove the dcmdump-specific formatting. \
      sed \
        -e 's/\(([0-9a-f]\{4\},[0-9a-f]\{4\})\) [A-Z][A-Z] \[\(.*\)\].*#.*/\1 \2/' \
        -e 's/\(([0-9a-f]\{4\},[0-9a-f]\{4\})\) US \(.*\) \+#.*/\1 \2/' \
        -e 's/\\/\\\\/g' | while read tag data; do
          # Copy the values onto all files in the specified directory
          info "    Setting ${tag}=${data}"
          "${dcmodify}" \
            --no-backup \
            --insert "$tag"="$data" \
            "${output_dir}"/*
      done

  info "  copyDCMTags done"
}

# Export the function to be used when sourced, but do not allow the script to be called directly
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  export -f copyDCMTags
else
  echo "getDCMTag is an internal function and cannot be called directly."
  exit 1
fi
