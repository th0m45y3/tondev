#!/bin/bash
set -e

if [[ $1 != *".tvc"  ]] ; then 
    echo "ERROR: GIVER file name .tvc required!"
    echo ""
    echo "USAGE:"
    echo "  ${0} FILENAME ADDRESS"
    echo "    where:"
    echo "      FILENAME - optional, default is wallet.tvc"
    echo "      ADDRESS  - required, raw address of wallet"
    echo ""
    echo "example:"
    echo "  ${0} wallet.tvc 0:53bebce9e093a10fcbb84d1116a9dc7a2364c9ee6da801859b2361ab2db74316"
    exit 1
fi

GIVER_NAME=${1%.*}
GIVER_ADDRESS=$2

# Check if tonos-cli installed 
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

function get_address {
    echo $(cat $1.log | grep "Raw address:" | cut -d ' ' -f 3)
}

function genaddr {
    $tos genaddr $1.tvc $1.abi.json --genkey $1.keys.json > $1.log
}

function decodeGIVER {
    $tos decode stateinit $1.tvc --tvc > $1.txt
    $(tail -n 12 $1.txt > $1.decode.json)
}

echo "_______________________________________________________________"
echo "STEP 0: calculating GIVER address"
echo "_______________________________________________________________"
genaddr $GIVER_NAME
GIVER_ADDRESS=$(get_address $GIVER_NAME)
echo $GIVER_ADDRESS

echo "_______________________________________________________________"
echo "STEP 1: waiting for money transfer"
echo "_______________________________________________________________"
echo "Please send money to $GIVER_ADDRESS"
sleep 5
echo "waiting..."
sleep 5

echo "STEP 2: creating dabi. Please use extraton to send tokens to address: $GIVER_ADDRESS"
echo "_______________________________________________________________"

GIVER_DABI=$(cat $GIVER_NAME.abi.json | xxd -ps -c 20000)
GIVER_DABI="$(echo -e "${GIVER_DABI}" | tr -d '[:space:]')"
echo "{\"dabi\":\"$GIVER_DABI\"}" > $GIVER_NAME.dabi.json


echo "Step 3. Deploying GIVER"
echo "_______________________________________________________________" #"{\"dabi\":\"$GIVER_DABI\"}" \
$tos --url https://net.ton.dev deploy $GIVER_NAME.tvc $GIVER_NAME.dabi.json \
    --sign keys.json \
    --abi $GIVER_NAME.abi.json #1>/dev/null

echo "Done! Deployed giver with address: $GIVER_ADDRESS"
# echo "Step 0. Save decoded stateInit in $GIVER_NAME.decode.json"
# decodeGIVER