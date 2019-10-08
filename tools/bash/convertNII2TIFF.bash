#!/usr/bin/env bash
#
# Convert NIfTI file to TIFF images using med2image
#

function convertNII2TIFF {
  # Input NIfTI file
  local input_nii="${1}"
  # Desired output directory
  local output="${2}"

  info "convertNII2TIFF start"

  # Output file prefix (CAVE: Re-used elsewhere, do not change)
  local output_file_prefix="bia"

  # Use med2image to convert the NIfTI file to separate TIFF files
  ${med2image} \
    --inputFile "$input_nii" \
    --outputFileStem "${output_file_prefix}.tiff" \
    --outputDir "${output}" 1>/dev/null || error "med2image failed"

  # Force the numbering to start with 001 instead of 000 and rename file accordingly
  # Rename files in parallel using GNU parallel's sem
  ls -1 "${output}/${output_file_prefix}-slice"*.tiff | tac | while read slice; do
    slice_no=$(echo $slice | sed -re 's/.*slice([0-9]+)\.tiff/\1/')
    printf -v slice_no_incr "%03d" $(echo "$slice_no + 1" | bc)
    LANG=C ${sem} -j+0 "mv '$slice' '${output}/${output_file_prefix}-slice${slice_no_incr}.tiff'"
  done

  info "convertNII2TIFF done"
}

# Export the function to be used when sourced, but do not allow the script to be called directly
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  export -f convertNII2TIFF
else
  echo "convertNII2TIFF is an internal function and cannot be called directly."
  exit 1
fi
