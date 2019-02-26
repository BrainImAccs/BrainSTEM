#!/usr/bin/env bash
#
# This script just uses storescu to send all DICOM files within a directory to the PACS
#

function sendDCM {
  # Directory containing the DICOM files to send
  local dir="${1}"
  # Optionally propose a transmission transfer syntax
  local transmission_transfer_syntax="${2:-}"

  # Check for transmission transfer syntaxes and set those
  local add_transmission_transfer_syntax=""
  if [[ "$transmission_transfer_syntax" == "jpeg8" ]]; then
    add_transmission_transfer_syntax="--propose-jpeg8"
  fi

  info "sendDCM start"

  "${storescu}" \
    --scan-directories \
    ${add_transmission_transfer_syntax} \
    --call ${called_aetitle} \
    ${peer} ${port} \
    "${dir}"

  info "sendDCM done"
}

# Export the function to be used when sourced, but do not allow the script to be called directly
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  export -f sendDCM
else
  echo "sendDCM is an internal function and cannot be called directly."
  exit 1
fi
