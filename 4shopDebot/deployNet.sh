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
CONTRACT_NAME=${2%.*:-DEBOT_NAME%Debot*}
NETWORK="http://net.ton.dev"
GIVER_NAME=wallet
GIVER_ADDRESS=0:8c5cb701575c92b73480434ee37e2a87f004cdf6e69a82c931c23a1cd8cbe311


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
    $tos --url $NETWORK call $GIVER_ADDRESS \
        sendmoney "{\"dest\":\"$1\",\"amount\":1000000000}" \
        --abi $GIVER_NAME.abi.json \
        --sign $GIVER_NAME.keys.json
        #1>/dev/null
}

function get_address {
    echo $(cat $1.log | grep "Raw address:" | cut -d ' ' -f 3)
}

function genaddr {
    $tos genaddr $1.tvc $1.abi.json --genkey $1.keys.json > $1.log
}

function decodecontract {
    $tos decode stateinit $1.tvc --tvc > $1.txt
    $(tail -n 12 $1.txt > $1.decode.json)
}

function setCode {
    echo $(jq .code $1.decode.json)
}

function setData {
    echo $(jq .data $1.decode.json)
}

echo "_______________________________________________________________"
echo "STEP 0: decode stateinit"
echo "_______________________________________________________________"
$(decodecontract $CONTRACT_NAME)
TODO_CODE=$(setCode $CONTRACT_NAME)
echo "code: $TODO_CODE" #############################
TODO_DATA=$(setData $CONTRACT_NAME)
echo "data: $TODO_DATA" #############################

echo "_______________________________________________________________"
echo "STEP 1: calculating debot address"
echo "_______________________________________________________________"
echo "Contract name:$CONTRACT_NAME" #################
genaddr $DEBOT_NAME
DEBOT_ADDRESS=$(get_address $DEBOT_NAME)
echo $DEBOT_ADDRESS                 #################
giver $DEBOT_ADDRESS

echo "_______________________________________________________________"
echo "STEP 2: creating dabi"
echo "_______________________________________________________________"
#giver $DEBOT_ADDRESS
DEBOT_DABI=$(cat $DEBOT_NAME.abi.json | xxd -ps -c 20000)
DEBOT_DABI="$(echo -e "${DEBOT_DABI}" | tr -d '[:space:]')" #> $DEBOT_NAME.dabi.json

echo "_______________________________________________________________"
echo "Step 3. deploying contract"
echo "_______________________________________________________________"
$tos --url $NETWORK deploy $DEBOT_NAME.tvc "{}" \
    --sign $DEBOT_NAME.keys.json \
    --abi $DEBOT_NAME.abi.json #1>/dev/null

echo "_______________________________________________________________"
echo "STEP 4: setting abi file"
echo "_______________________________________________________________"
$tos --url $NETWORK call $DEBOT_ADDRESS setABI "{\"dabi\":\"$DEBOT_DABI\"}" \
    --sign $DEBOT_NAME.keys.json \
    --abi $DEBOT_NAME.abi.json #1>/dev/null

echo "_______________________________________________________________"
echo "STEP 5: call setTodoCode"
echo "_______________________________________________________________"
$tos --url $NETWORK call $DEBOT_ADDRESS \
    setTodoCode "{\"code\":$TODO_CODE,\"data\":$TODO_DATA}" \
    --abi $DEBOT_NAME.abi.json  --sign $DEBOT_NAME.keys.json
     # 1>/dev/null

echo "_______________________________________________________________"
echo "STEP 6: call setIcon"
echo "_______________________________________________________________"
#ICON_BYTES=$(base64 -w 0 $DEBOT_NAME.png)
#ICON=$(echo -n "data:image/png;base64,$ICON_BYTES" | xxd -ps -c 20000)
#$tos --url $NETWORK call $DEBOT_ADDRESS  \
#    setIcon "{\"icon\":\"$ICON\"}"  \
#    --abi $DEBOT_NAME.abi.json --sign $DEBOT_NAME.keys.json

echo "_______________________________________________________________"
echo "Done! Deployed debot with address: $DEBOT_ADDRESS"
# echo "Step 0. Save decoded stateInit in $CONTRACT_NAME.decode.json"
# decodecontract