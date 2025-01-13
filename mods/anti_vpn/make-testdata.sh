#!/bin/bash

[[ -z "${VPNAPI_APIKEY}" ]] && {
    echo "ERROR: You must set VPNAPI_APIKEY to your api key."
    exit 1
}

mkdir -p testdata

# TODO: Make sure that these are IP addrs.  Bad data can trash your filesystem.
for IP in $*; do
    FILE="testdata/${IP}.json"
    URL="https://vpnapi.io/api/${IP}?key=${VPNAPI_APIKEY}"
    wget -O ${FILE} ${URL}
done
