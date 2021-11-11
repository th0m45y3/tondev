#!/bin/bash
set -e

if [[ $1 != *".tvc"  ]] ; then 
    echo "ERROR: contract file name .tvc required!"
    echo ""
    echo "USAGE:"
    echo "  ${0} FILENAME NETWORK"
    echo "    where:"
    echo "      FILENAME - required, debot tvc file name"
    echo "      ADDRESS  - optional, giver address default is 0:17ffbfa96258ea4fa1b65ed77db8d8dc4adc39d561551293cab1e7ba3030fbd3"
    echo ""
    echo "PRIMER:"
    echo "  ${0} mydebot.tvc 0:53bebce9e093a10fcbb84d1116a9dc7a2364c9ee6da801859b2361ab2db74316"
    exit 1
fi

DEBOT_NAME=${1%.*} 
DEBOT_ADDRESS=${2}
NETWORK="http://net.ton.dev"
GIVER_NAME=wallet
GIVER_ADDRESS=0:8c5cb701575c92b73480434ee37e2a87f004cdf6e69a82c931c23a1cd8cbe311
tos=./tonos-cli
if $tos --version > /dev/null 2>&1; then
    echo "OK $tos installed locally."
else 
    tos=tonos-cli
    if $tos --version > /dev/null 2>&1; then
        echo "OK $tos installed globally."
    else 
        echo "$tos not found globally or in the current directory. Please install it and rerun script."
    fi
fi

ICON_BYTES=$(base64 -w 0 $DEBOT_NAME.png)
ICON_BYTES=$(echo $ICON_BYTES | tr -d 'n')
ICON_BYTES=$(echo $ICON_BYTES | tr -d '[:space:]')

ICON=$(echo -n "data:image/png;base64,$ICON_BYTES" | xxd -ps -c 20000)
ICON=$(echo $ICON | tr -d '[:space:]')
ICON=$(echo $ICON | tr -d '\n')
ABIJSON=$(echo $DEBOT_NAME.abi.json | tr -d '\n')
ABIJSON=$(echo $ABIJSON | tr -d '[:space:]')

$tos --url $NETWORK call $DEBOT_ADDRESS  \
    setIcon "{\"icon\":\"$ICON\"}"  \
    --abi $ABIJSON --sign $DEBOT_NAME.keys.json
