#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Deploying Chaincode On Pharma Network"
echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
VERSION="$4"
TYPE="$5"
: ${CHANNEL_NAME:="pharmachannel"}
: ${DELAY:="5"}
: ${LANGUAGE:="node"}
: ${VERSION:=1.1}
: ${TYPE="basic"}

LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
ORGS="manufacturer distributor retailer transporter"
TIMEOUT=15
COUNTER=1
MAX_RETRY=20
PACKAGE_ID=""
CC_RUNTIME_LANGUAGE="node"
CC_SRC_PATH="/opt/gopath/src/github.com/hyperledger/fabric/peer/chaincode/"


echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh


## at first we package the chaincode
echo "Packaging chaincode on peer0.manufacturer.pharma.net ..."
packageChaincode $VERSION 0 'manufacturer'

## Install new version of chaincode on peer0 of all 3 orgs making them endorsers
echo "Installing chaincode on peer0.manufacturer.pharma.net ..."
installChaincode 0 'manufacturer'
echo "Installing chaincode on peer0.distributor.pharma.net ..."
installChaincode 0 'distributor'
echo "Installing chaincode on peer0.retailer.pharma.net ..."
installChaincode 0 'retailer'
echo "Installing chaincode on peer0.transporter.pharma.net ..."
installChaincode 0 'transporter'

## Query whether the chaincode is installed for manufacturer - peer0
queryInstalled 0 'manufacturer'
## Approve the definition for manufacturer - peer0
approveForMyOrg $VERSION 0 'manufacturer'
## Query whether the chaincode is installed for distributor - peer0
queryInstalled 0 'distributor'
## Approve the definition for distributor - peer0
approveForMyOrg $VERSION 0 'distributor'
## Query whether the chaincode is installed for retailer - peer0
queryInstalled 0 'retailer'
## Approve the definition for retailer - peer0
approveForMyOrg $VERSION 0 'retailer'
## Query whether the chaincode is installed for transporter - peer0
queryInstalled 0 'transporter'
## Approve the definition for transporter - peer0
approveForMyOrg $VERSION 0 'transporter'

## now that all orgs have approved the definition, commit the definition
echo "Committing chaincode definition on channel after getting approval from majority orgs..."
commitChaincodeDefinition $VERSION 0 'manufacturer' 0 'distributor' 0 'retailer' 0 'transporter'

## Invoke chaincode first time with --isInit flag to instantiate the chaincode
echo "Invoking chaincode with --isInit flag to instantiate the chaincode on channel..."
chaincodeInvoke 0 'manufacturer' 0 'distributor' 0 'retailer' 0 'transporter'

echo
echo "========= All GOOD, Chaincode Is Now Installed & Instantiated On Network =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
