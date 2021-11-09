#!/bin/bash
set -e

if [[ $1 != *".tvc" ]] ; then 
    echo "ERROR: Missing some of required .tvc files!"
    echo "USAGE: ${0} FILENAME NETWORK"
    echo "WHERE:"
    echo "  FILENAME - required, debot .tvc filename"
    echo "  NETWORK  - optional, network endpoint, default is https://net.ton.dev"
    echo "EXAMPLE: ${0} mydebot.tvc https://net.ton.dev"
    exit 1
fi

DEBOT_NAME=${1%.*}
GIVER_NAME=Giver
CONTRACT_NAME=ShoppingList
NETWORK="${2:-https://net.ton.dev}"
# My giver address
GIVER_ADDRESS=0:2105523b014653c8f00ee01117a3eee3dd9fff1537a4b718b526a8bac82b2ba4
 
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


function topUpAccount {
    $tos --url $NETWORK call $GIVER_ADDRESS \
    sendAndPayFees "{\"destination\":\"$1\",\"value\":1000000000}" \
    --abi $GIVER_NAME.abi.json \
    --sign $GIVER_NAME.keys.json
}

function getAddress {
    echo $(cat $1.log | grep "Raw address:" | cut -d ' ' -f 3)
}

function generateAddress {
    $tos genaddr $1.tvc $1.abi.json --genkey $1.keys.json > $1.log
}

echo "Step 1. Calculating DeBot address..."
generateAddress $DEBOT_NAME
DEBOT_ADDRESS=$(getAddress $DEBOT_NAME)

echo "Step 2. Sending tokens to address: $DEBOT_ADDRESS..."
topUpAccount $DEBOT_ADDRESS #1>/dev/null
DEBOT_ABI=$(cat $DEBOT_NAME.abi.json | xxd -p -c 20000)
DEBOT_ABI="$(echo -e "${DEBOT_ABI}" | tr -d '[:space:]')"
echo "{\"dabi\":\"$DEBOT_ABI\"}" > $DEBOT_NAME.dabi.json

echo "Step 3. Deploying DeBot..."
$tos --url $NETWORK deploy $DEBOT_NAME.tvc "{}" \
    --sign $DEBOT_NAME.keys.json \
    --abi $DEBOT_NAME.abi.json 1>/dev/null

$tos --url $NETWORK call $DEBOT_ADDRESS setABI $DEBOT_NAME.dabi.json\
    --sign $DEBOT_NAME.keys.json \
    --abi $DEBOT_NAME.abi.json  1>/dev/null

$tos decode stateinit --tvc $CONTRACT_NAME.tvc > $CONTRACT_NAME.log
tail -n12 $CONTRACT_NAME.log > $CONTRACT_NAME.decode.json
$tos --url $NETWORK call $DEBOT_ADDRESS buildStateInit $CONTRACT_NAME.decode.json \
    --sign $DEBOT_NAME.keys.json \
    --abi $DEBOT_NAME.abi.json 1>/dev/null

echo "Done! DeBot was deployed at: $DEBOT_ADDRESS"