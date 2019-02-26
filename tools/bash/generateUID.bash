#!/usr/bin/env bash
#
# This script generates a UID for DICOM tags 
#

function generateUID {
  # Prefix the "suffix" part of the UID
  local prefix="${1}"

  # Test if the prefix supplied is a number
  if [[ ! $prefix =~ ^[0-9]+$ ]]; then
    error "  Prefix for UID has to be a number!"
  fi

  # The prefix cannot start with a zero (unless it's only a zero)
  if [[ $prefix =~ ^0[0-9]+$ ]]; then
    error "  Prefix for UID cannot start with zero!"
  fi

  # Organization Identified (Source: https://www.medicalconnections.co.uk/FreeUID/)
  local OID="1.2.826.0.1.3680043.10.102"

  # Get main network device and use it as unique reference for the server in DICOM UIDs
  #
  # 1. The main network device is chosen by the route to the PACS peer
  local main_network_interface=$(/sbin/ip route get "${peer}" | \
    grep ' dev ' | head -n1 | \
    sed -e 's/.* dev \([[:alnum:]]\+\).*/\1/'
  )

  # Optionally use the following line to use the device for the default route
  # main_network_interface=$(/sbin/ip route | grep -E '^default' | grep ' dev ' | head -n1 | sed -e 's/.* dev \([[:alnum:]]\+\).*/\1/')

  # 2. The device's hardware (MAC) address is then converted to decimal using bc
  local hwaddr_decimal=$(echo "ibase=16; $(ip link show ${main_network_interface} | \
    grep ether | head -n1 | \
    sed -e 's/.* \(\([[:xdigit:]]\{1,2\}:\)\{5\}[[:xdigit:]]\{1,2\}\) .*/\U\1/' -e 's/://g')" | \
  bc)

  # Generate UID by concatting OID, prefix, up to 5 random numbers, hardware address, date and time
  echo $(echo ${OID}.${prefix}$(shuf -i 1-99999 -n1)${hwaddr_decimal}$(date "+%Y%m%d%H%M%S"))
}

# Export the function to be used when sourced, but do not allow the script to be called directly
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  export -f generateUID
else
  echo "generateUID is an internal function and cannot be called directly."
  exit 1
fi
