#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/pharma.net/orderers/orderer.pharma.net/msp/tlscacerts/tlsca.pharma.net-cert.pem
PEER0_MANUFACTURER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/manufacturer.pharma.net/peers/peer0.manufacturer.pharma.net/tls/ca.crt
PEER0_DISTRIBUTOR_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/distributor.pharma.net/peers/peer0.distributor.pharma.net/tls/ca.crt
PEER0_RETAILER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/retailer.pharma.net/peers/peer0.retailer.pharma.net/tls/ca.crt
# PEER0_CONSUMER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/consumer.pharma.net/peers/peer0.consumer.pharma.net/tls/ca.crt
PEER0_TRANSPORTER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/transporter.pharma.net/peers/peer0.transporter.pharma.net/tls/ca.crt


# verify the result of the end-to-end test
verifyResult() {
 if [ "$1" -ne 0 ]; then
   echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
   echo "========= ERROR !!! FAILED to execute Bootstrap ==========="
   echo
   exit 1
 fi
}

setGlobals() {
  PEER=$1
  ORG=$2
  if [ "$ORG" == 'manufacturer' ]; then
    CORE_PEER_LOCALMSPID="manufacturerMSP"
    CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_MANUFACTURER_CA
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/manufacturer.pharma.net/users/Admin@manufacturer.pharma.net/msp
    if [ "$PEER" -eq 0 ]; then
      CORE_PEER_ADDRESS=peer0.manufacturer.pharma.net:7051
    else
      CORE_PEER_ADDRESS=peer1.manufacturer.pharma.net:8051
    fi
  elif [ "$ORG" == 'distributor' ]; then
    CORE_PEER_LOCALMSPID="distributorMSP"
    CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_DISTRIBUTOR_CA
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/distributor.pharma.net/users/Admin@distributor.pharma.net/msp
    if [ "$PEER" -eq 0 ]; then
      CORE_PEER_ADDRESS=peer0.distributor.pharma.net:9051
    fi
    if [ "$PEER" -eq 1 ]; then
      CORE_PEER_ADDRESS=peer1.distributor.pharma.net:10051
    fi
  elif [ "$ORG" == 'retailer' ]; then
    CORE_PEER_LOCALMSPID="retailerMSP"
    CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_RETAILER_CA
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/retailer.pharma.net/users/Admin@retailer.pharma.net/msp
    if [ "$PEER" -eq 0 ]; then
      CORE_PEER_ADDRESS=peer0.retailer.pharma.net:11051
    fi
    if [ "$PEER" -eq 1 ]; then
      CORE_PEER_ADDRESS=peer1.retailer.pharma.net:12051
    fi
  elif [ "$ORG" == 'transporter' ]; then
    CORE_PEER_LOCALMSPID="transporterMSP"
    CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_TRANSPORTER_CA
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/transporter.pharma.net/users/Admin@transporter.pharma.net/msp
    if [ "$PEER" -eq 0 ]; then
      CORE_PEER_ADDRESS=peer0.transporter.pharma.net:13051
    fi
    if [ "$PEER" -eq 1 ]; then
      CORE_PEER_ADDRESS=peer1.transporter.pharma.net:14051
    fi
  # elif [ "$ORG" == 'consumer' ]; then
  #   CORE_PEER_LOCALMSPID="consumerMSP"
  #   CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_CONSUMER_CA
  #   CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/consumer.pharma.net/users/Admin@consumer.pharma.net/msp
  #   if [ "$PEER" -eq 0 ]; then
  #     CORE_PEER_ADDRESS=peer0.consumer.pharma.net:13051
  #   fi
  #   if [ "$PEER" -eq 1 ]; then
  #     CORE_PEER_ADDRESS=peer1.consumer.pharma.net:14051
  #   fi
  else
    echo "================== ERROR !!! ORG Unknown =================="
  fi
}

updateAnchorPeers() {
  PEER=$1
  ORG=$2
  setGlobals "$PEER" "$ORG"

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer channel update -o orderer.pharma.net:7050 -c "$CHANNEL_NAME" -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx >&log.txt
    res=$?
    set +x
  else
    set -x
    peer channel update -o orderer.pharma.net:7050 -c "$CHANNEL_NAME" -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls "$CORE_PEER_TLS_ENABLED" --cafile $ORDERER_CA >&log.txt
    res=$?
    set +x
  fi
  cat log.txt
  verifyResult $res "Anchor peer update failed"
  echo "===================== Anchor peers updated for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME' ===================== "
  sleep "$DELAY"
  echo
}

## Sometimes Join takes time hence RETRY at least 5 times
joinChannelWithRetry() {
  PEER=$1
  ORG=$2
  setGlobals "$PEER" "$ORG"

  set -x
  peer channel join -b "$CHANNEL_NAME".block >&log.txt
  res=$?
  set +x
  cat log.txt
  if [ $res -ne 0 -a "$COUNTER" -lt "$MAX_RETRY" ]; then
    COUNTER=$(expr "$COUNTER" + 1)
    echo "peer${PEER}.${ORG} failed to join the channel, Retry after $DELAY seconds"
    sleep "$DELAY"
    joinChannelWithRetry "$PEER" "$ORG"
  else
    COUNTER=1
  fi
  verifyResult $res "After $MAX_RETRY attempts, peer${PEER}.${ORG} has failed to join channel '$CHANNEL_NAME' "
}

# packageChaincode VERSION PEER ORG
packageChaincode() {
  VERSION=$1
  PEER=$2
  ORG=$3
  setGlobals "$PEER" "$ORG"
  set -x
  peer lifecycle chaincode package pharmanet.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label pharma_${VERSION} >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode packaging on peer${PEER}.${ORG} has failed"
  echo "===================== Chaincode is packaged on peer${PEER}.${ORG} ===================== "
  echo
}

installChaincode() {
  PEER=$1
  ORG=$2
  setGlobals "$PEER" "$ORG"
  set -x
  peer lifecycle chaincode install pharmanet.tar.gz >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode installation on peer${PEER}.${ORG} has failed"
  echo "===================== Chaincode is installed on peer${PEER}.${ORG} ===================== "
  echo
}

# queryInstalled PEER ORG
queryInstalled() {
  PEER=$1
  ORG=$2
  setGlobals "$PEER" "$ORG"
  set -x
  peer lifecycle chaincode queryinstalled >&log.txt
  res=$?
  set +x
  cat log.txt
  PACKAGE_ID=`sed -n '/Package/{s/^Package ID: //; s/, Label:.*$//; p;}' log.txt`
  verifyResult $res "Query installed on peer${PEER}.${ORG} has failed"
  echo PackageID For Chaincode Definition is ${PACKAGE_ID}
  echo "===================== Chaincode Package installed successfully on peer${PEER}.${ORG} ===================== "
  echo
}

# approveForMyOrg VERSION PEER ORG
approveForMyOrg() {
  VERSION=$1
  PEER=$2
  ORG=$3
  setGlobals "$PEER" "$ORG"

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer lifecycle chaincode approveformyorg --channelID $CHANNEL_NAME --name pharmanet --version ${VERSION} --init-required --package-id ${PACKAGE_ID} --sequence 1 --waitForEvent >&log.txt
    set +x
  else
    set -x
    peer lifecycle chaincode approveformyorg --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name pharmanet --version ${VERSION} --init-required --package-id ${PACKAGE_ID} --sequence 1 --waitForEvent >&log.txt
    set +x
  fi
  cat log.txt
  verifyResult $res "Chaincode definition approved on peer${PEER}.${ORG} on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode definition approved on peer${PEER}.${ORG} on channel '$CHANNEL_NAME' ===================== "
  echo
}

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
commitChaincodeDefinition() {
  VERSION=$1
  shift
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer lifecycle chaincode commit -o orderer.pharma.net:7050 --channelID $CHANNEL_NAME --name pharmanet $PEER_CONN_PARMS --version ${VERSION} --sequence 1 --init-required >&log.txt
    res=$?
    set +x
  else
    set -x
    peer lifecycle chaincode commit -o orderer.pharma.net:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name pharmanet $PEER_CONN_PARMS --version ${VERSION} --sequence 1 --init-required >&log.txt
    res=$?
    set +x
  fi
  cat log.txt
  verifyResult $res "Chaincode definition commit failed on peer${PEER}.${ORG} on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode definition committed on channel '$CHANNEL_NAME' ===================== "
  echo
}

# parsePeerConnectionParameters $@
# Helper function that takes the parameters from a chaincode operation
# (e.g. invoke, query, instantiate) and checks for an even number of
# peers and associated org, then sets $PEER_CONN_PARMS and $PEERS
parsePeerConnectionParameters() {
  # check for uneven number of peer and org parameters
  if [ $(($# % 2)) -ne 0 ]; then
    exit 1
  fi

  PEER_CONN_PARMS=""
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1 $2
    PEER="peer$1.$2"
    PEERS="$PEERS $PEER"
    PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $CORE_PEER_ADDRESS"
    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "true" ]; then
      TLSINFO=$(eval echo "--tlsRootCertFiles \$PEER$1_$2_CA")
      PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"
    fi
    # shift by two to get the next pair of peer/org parameters
    shift
    shift
  done
  # remove leading space for output
  PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
}

chaincodeInvoke() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer chaincode invoke -o orderer.pharma.net:7050 -C $CHANNEL_NAME -n pharmanet $PEER_CONN_PARMS -c '{"Args":["net.pharma.user:instantiate"]}' --isInit >&log.txt
    res=$?
    set +x
  else
    set -x
    peer chaincode invoke -o orderer.pharma.net:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n pharmanet $PEER_CONN_PARMS -c '{"Args":["net.pharma.user:instantiate"]}' --isInit >&log.txt
    res=$?
    set +x
  fi
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
  echo
}

upgradeChaincode() {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  VERSION=$3

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer chaincode upgrade -o orderer.pharma.net:7050 -C $CHANNEL_NAME -n pharmanet -l ${LANGUAGE} -v ${VERSION} -p ${CC_SRC_PATH} -c '{"Args":["net.pharma.user:instantiate"]}' -P "OR ('manufacturerMSP.member','distributorMSP.member')" >&log.txt
    res=$?
    set +x
  else
    set -x
    peer chaincode upgrade -o orderer.pharma.net:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n pharmanet -l ${LANGUAGE} -v ${VERSION} -p ${CC_SRC_PATH} -c '{"Args":["net.pharma.user:instantiate"]}' -P "OR ('manufacturerMSP.member','distributorMSP.member')" >&log.txt
    res=$?
    set +x
  fi
  cat log.txt
  verifyResult $res "Chaincode upgrade on peer${PEER}.${ORG} has failed"
  echo "===================== Chaincode is upgraded on peer${PEER}.${ORG} on channel '$CHANNEL_NAME' ===================== "
  echo
}
