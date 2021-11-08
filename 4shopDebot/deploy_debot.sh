#!/bin/bash
set -e

if [[ $1 != *".tvc"  ]] ; then 
    echo "ERROR: contract file name .tvc required!"
    echo ""
    echo "USAGE:"
    echo "  ${0} FILENAME NETWORK"
    echo "    where:"
    echo "      FILENAME - required, debot tvc file name"
    echo "      NETWORK  - optional, network endpoint, default is http://127.0.0.1"
    echo ""
    echo "PRIMER:"
    echo "  ${0} mydebot.tvc https://net.ton.dev"
    exit 1
fi

DEBOT_NAME=${1%.*} 
CONTRACT_NAME=${1%Debot*}
NETWORK="${2:-http://127.0.0.1}"
todo_code=$CONTRACT_NAME.decode.json

# net.ton.dev 
GIVER_ADDRESS=0:f17d533a33604cbfd106fd367830ee705d4afeee95682bc836e4847a89e807d5


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


function giver {
    $tos --url $NETWORK call \
        --abi ../giver.abi.json \
        --sign ../giver.keys.json \
        $GIVER_ADDRESS \
        sendTransaction "{\"dest\":\"$1\",\"value\":10000000000,\"bounce\":false}" #\
        #1>/dev/null
}

function get_address {
    echo $(cat $1.log | grep "Raw address:" | cut -d ' ' -f 3)
}

function genaddr {
    $tos genaddr $1.tvc $1.abi.json --genkey keys.json > $1.log
}

function decodecontract {
    decderes = $($tos decode stateinit $1.tvc)
    printf decderes*:% > $1.decode.json
}

# echo "______________CANNOT_RUN_FROM_BUSH>USE_POWERSHELL_______________________________________________"
# echo "STEP 0: decode stateinit"
# decodecontract $CONTRACT_NAME 

echo "_______________________________________________________________"
echo "STEP 1: calculating debot address"
echo "Contract name:$CONTRACT_NAME"
genaddr $DEBOT_NAME
DEBOT_ADDRESS=$(get_address $DEBOT_NAME)

echo "STEP 2: creating dabi. [use extraton to] Send tokens to address: $DEBOT_ADDRESS"
echo "_______________________________________________________________"
#giver $DEBOT_ADDRESS
DEBOT_ABI=$(cat $DEBOT_NAME.abi.json | xxd -ps -c 20000)


echo "Step 3. Deploying contract"
echo "_______________________________________________________________"
$tos --url $NETWORK deploy $DEBOT_NAME.tvc "{}" \
    --sign keys.json \
    --abi $DEBOT_NAME.abi.json #1>/dev/null

echo "STEP 4: setting abi file"
echo "_______________________________________________________________"
$tos --url $NETWORK call $DEBOT_ADDRESS setABI "{\"dabi\":\"$DEBOT_ABI\"}" \
    --sign keys.json \
    --abi $DEBOT_NAME.abi.json #1>/dev/null

# echo "STEP 5: decode $CONTRACT_NAME.tvc"
# echo "_____________________CANNOT_RUN_FROM_BUSH>USE_POWERSHEL__________________________________________"
# todo_code=$(base64 -w 0 $CONTRACT_NAME.tvc)
# decodecontract

echo "STEP 5: call setTodoCode"
echo "_______________________________________________________________"
$tos --url $NETWORK call --abi $DEBOT_NAME.abi.json  \
    --sign keys.json \
    $DEBOT_ADDRESS setTodoCode $todo_code #"{\"code\":\"$todo_code\"}" \
     # 1>/dev/null

echo "Done! Deployed debot with address: $DEBOT_ADDRESS"
# echo "Step 0. Save decoded stateInit in $CONTRACT_NAME.decode.json"
# decodecontract