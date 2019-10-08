#!/usr/bin/env bash
#
# This script converts a NIfTI file into a stack of DICOM files.
#
# Since the NIFTI file does not contain most of the DICOM metadata, and "nifti2dicom" does not
# necessarily copy all the DICOM values we want in a reasonable fashion, we copy the relevant
# data from the reference DICOM file.
#

function convertNII2DCM {
  # Input NIfTI file
  local input_nii="${1}"
  # Output directory
  local output="${2}"
  # Series number to be used in the DICOM stack
  local series_no="${3}"
  # Descired DICOM series description
  local series_description="${4}"
  # Reference DICOM file (to copy DICOM values from)
  local ref_dcm="${5}"

  info "convertNII2DCM start"

  # Source the common functions for convert2DCM, if necessary
  if [[ ! "$(type -t sourceFunctions2DCM)" = "function" ]]; then
    local __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${__dir}/convert2DCM_common.bash"
  fi

  # Source necessary functions (if necessary)
  sourceFunctions2DCM

  # Get modality from the reference DICOM
  local modality=$(getDCMTag "${ref_dcm}" "0008,0060")

  # Get the acquisition number from the reference DICOM
  local acc_no=$(getAccNo "${ref_dcm}")
  info "  Accession Number will be ${acc_no}."

  # If replace_study_description (see setup.brainstem.bash) has been set, use it to replace the StudyDescription
  local do_replace_study_description=""
  if [[ "$replace_study_description" != "" ]]; then
    do_replace_study_description="--studydescription${replace_study_description}"
  fi

  # Run nifti2dicom to convert a NIfTI file into a stack of DICOM images, using above values and
  # information from the reference DICOM file
  #
  # This is not entirely stable, so we use timeout to potentially kill the process
  # (see setup.brainstem.bash)
  #
  timeout ${nifti2dicom_timeout} ${nifti2dicom} \
    -o "${output}" \
    -i "${input_nii}" \
    --modality ${modality} \
    --accessionnumber "${acc_no}" \
    ${do_replace_study_description} \
    --useoriginalseries --dicomheaderfile "${ref_dcm}" \
    --seriesnumber ${series_no} \
    --manufacturer "BrainImAccs" 1>/dev/null || error "nifti2dicom failed"

  # Copy the following DICOM tags from the reference DICOM file into the new DICOM stack:
  #
  #   0008,0016 SOPClassUID - this will automatically update 0002,0002 MediaStorageSOPClassUID
  #   0008,0020 StudyDate
  #   0008,0021 SeriesDate
  #   0008,0022 AcquisitionDate
  #   0008,0023 ContentDate
  #   0008,002A AcquisitionDateTime
  #   0008,0030 StudyTime
  #   0008,0031 SeriesTime
  #   0008,0032 AcquisitionTime
  #   0008,0033 ContentTime
  #   0008,0080 InstitutionName
  #   0008,0090 ReferringPhysiciansName
  #   0008,1010 StationName
  #   0008,1030 StudyDescription
  #   0018,0010 ContrastBolusAgent
  #   0018,0015 BodyPartExamined
  #   0018,1030 ProtocolName
  #   0028,1050 WindowCenter
  #   0028,1051 WindowWidth
  #   0028,1055 WindowCenterWidthExplanation

  copy_dcm_tags="
    0008,0016
    0008,0020
    0008,0021
    0008,0022
    0008,0023
    0008,002A
    0008,0030
    0008,0031
    0008,0032
    0008,0033
    0008,0080
    0008,0090
    0008,1010
    0008,1030
    0018,0010
    0018,0015
    0018,1030
    0028,1050
    0028,1051
    0028,1055
  "

  # Source the function copyDCMTags, if necessary
  if [[ ! "$(type -t copyDCMTags)" = "function" ]]; then
    local __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${__dir}/copyDCMTags.bash"
  fi

  # Copy the DICOM values from the tags defined above onto the generated stack of DICOM images
  copyDCMTags "${ref_dcm}" "${output}" "${copy_dcm_tags}"

  # Copy modality specific tags from the reference DICOM file
  case $modality in
    # CT-specific:
    #
    #   0018,1210 ConvolutionKernel
  "CT")
    copy_dcm_tags="
      0018,1210
    "

    # Copy the DICOM values from the tags defined above onto the generated stack of DICOM images
    copyDCMTags "${ref_dcm}" "${output}" "${copy_dcm_tags}"
    ;;
  esac

  # Set Series and Instance UID
  setSeriesAndInstanceUID "${output_dir}"

  info "convertNII2DCM done"
}

# Export the function to be used when sourced, but do not allow the script to be called directly
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  export -f convertNII2DCM
else
  echo "convertNII2DCM is an internal function and cannot be called directly."
  exit 1
fi
