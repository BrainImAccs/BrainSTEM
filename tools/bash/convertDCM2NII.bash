#!/usr/bin/env bash
#
# This script uses dcm2niix to convert a DICOM series into a NIfTI file
# Optionally, the default gzip compression of the resulting NIfTI file can be disabled.
#
# This script exports a variable "nii", which containts the path and filename of the NIfTI file.

function convertDCM2NII {
  # Input directory with DICOM files
  local input="${1}"
  # Output directory
  local output="${2}"
  # Optionally disable gzip compression by giving "n" as the third parameter
  local do_gzip="${3:-y}"

  info "convertDCM2NII start"

  # Validate $do_gzip
  if [[ ! $do_gzip =~ ^[yn]$ ]]; then
    warning "  do_gzip must be either 'y' or 'n', we assume 'y' here."
    $do_gzip = "y"
  fi

  # Run dcm2niix.
  # By default,
  # - do not search subdirectories (there should be none, anyway)
  # - do not create a BIDS sidecar
  # - merge any 2D slices from the same series (needed for some CT series)
  # - optionally turn of gzip compression
  ${dcm2niix} \
    -d 0 \
    -b n \
    -m y \
    -o "${output}" \
    -z ${do_gzip} \
    "${input}" 1>/dev/null

  # Declare nii as an array
  local extension="nii.gz"
  if [[ $do_gzip == "n" ]]; then
    extension="nii"
  fi

  # Find the resulting NIfTI files and export the full path and filename in the nii variable
  if [ -e "${output}"/*[0-9]_Tilt_[0-9]".${extension}" ]; then
    nii=($(ls -1t "${output}"/*[0-9]_Tilt_[0-9]".${extension}" | tac | head -n1))
  else
    nii=($(ls -1t "${output}"/*[0-9]".${extension}" | tac | head -n1))
  fi

  info "  fslreorient2std start"
    local nii_reoriented=$(echo ${nii} | sed -e 's/\.nii/-reoriented.nii/')
    "${FSLDIR}/bin/fslreorient2std" \
      "${nii}" \
      "${nii_reoriented}"
    nii=${nii_reoriented}
  info "  fslreorient2std done"

  export nii

  info "convertDCM2NII done"
}

# Export the function to be used when sourced, but do not allow the script to be called directly
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  export -f convertDCM2NII
else
  echo "convertDCM2NII is an internal function and cannot be called directly."
  exit 1
fi
