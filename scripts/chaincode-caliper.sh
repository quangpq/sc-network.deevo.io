#!/bin/bash
export GOPATH=/opt/gopath
export GOROOT=/opt/go
export PATH="$PATH:$GOROOT/bin:$GOPATH/bin"
usage() { echo "Usage: $0 [-c <channelname>] -n [chaincodename]" 1>&2; exit 1; }
while getopts ":c:n:" o; do
    case "${o}" in
        c)
            c=${OPTARG}
            ;;
        n)
            n=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))
if [ -z "${c}" ] || [ -z "${n}" ] ; then
    usage
fi
echo "create channel channelID ${c} chaincodeName ${n} "

DATA=/home/ubuntu/hyperledgerconfig/data
export FABRIC_CFG_PATH=$DATA/
PEER_ORGS="org1 org2 org3 org4 org5"
NUM_PEERS=5
CHANNEL_NAME=${c}
CHANNEL_TX_FILE=$DATA/$CHANNEL_NAME.tx
CA_CHAINFILE=${DATA}/org0-ca-cert.pem
ORDERER_HOST=orderer0.org0.deevo.com
export ORDERER_PORT_ARGS=" -o orderer0.org0.deevo.com:7050 --tls --cafile $CA_CHAINFILE --clientauth"
QUERY_TIMEOUT=30

# install chaincode on peer1-org1, peer1-org2
for ORG in $PEER_ORGS; do
    #initPeerVars $ORG 1
    PEER_HOST=peer0.${ORG}.deevo.com
    PEER_NAME=${PEER_HOST}
    ORG_ADMIN_HOME=$DATA/orgs/$ORG/admin
    CA_CHAINFILE=${DATA}/${ORG}-ca-cert.pem
    export FABRIC_CA_CLIENT_HOME=$ORG_ADMIN_HOME
    export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
    export CORE_PEER_MSPCONFIGPATH=$ORG_ADMIN_HOME/msp
    export CORE_PEER_ID=$PEER_HOST
    export CORE_PEER_ADDRESS=$PEER_HOST:7051
    export CORE_PEER_LOCALMSPID=${ORG}MSP
    export CORE_LOGGING_LEVEL=DEBUG
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_TLS_CLIENTAUTHREQUIRED=true
    export CORE_PEER_TLS_ROOTCERT_FILE=$CA_CHAINFILE
    export CORE_PEER_TLS_CLIENTCERT_FILE=$DATA/tls/$PEER_NAME-cli-client.crt
    export CORE_PEER_TLS_CLIENTKEY_FILE=$DATA/tls/$PEER_NAME-cli-client.key
    export CORE_PEER_PROFILE_ENABLED=true
    # gossip variables
    export CORE_PEER_GOSSIP_USELEADERELECTION=true
    export CORE_PEER_GOSSIP_ORGLEADER=false
    echo "Install for $PEER_HOST ..."
    export ORDERER_PORT_ARGS=" -o orderer0.org0.deevo.com:7050 --tls --cafile $DATA/org0-ca-cert.pem --clientauth"
    export ORDERER_CONN_ARGS="$ORDERER_PORT_ARGS --keyfile $CORE_PEER_TLS_CLIENTKEY_FILE --certfile $CORE_PEER_TLS_CLIENTCERT_FILE"
    echo $ORDERER_CONN_ARGS
    $GOPATH/src/github.com/hyperledger/fabric/build/bin/peer chaincode install -n $n -v 1.0 -p github.com/hyperledger/caliper/src/contract/fabric/simple/go
    #$GOPATH/src/github.com/hyperledger/fabric/build/bin/peer chaincode install -n ${n} -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02
    sleep 5
done
sleep 10 
$GOPATH/src/github.com/hyperledger/fabric/build/bin/peer chaincode list --installed -C $CHANNEL_NAME
#initPeerVars ${PORGS[1]} 1
#switchToAdminIdentity
ORG=org1
PEER_HOST=peer0.${ORG}.deevo.com
PEER_NAME=${PEER_HOST}
ORG_ADMIN_HOME=$DATA/orgs/$ORG/admin
CA_CHAINFILE=${DATA}/${ORG}-ca-cert.pem
export FABRIC_CA_CLIENT_HOME=$ORG_ADMIN_HOME
export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
export CORE_PEER_MSPCONFIGPATH=$ORG_ADMIN_HOME/msp
export CORE_PEER_ID=$PEER_HOST
export CORE_PEER_ADDRESS=$PEER_HOST:7051
export CORE_PEER_LOCALMSPID=${ORG}MSP
export CORE_LOGGING_LEVEL=DEBUG
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_CLIENTAUTHREQUIRED=true
export CORE_PEER_TLS_ROOTCERT_FILE=$CA_CHAINFILE
export CORE_PEER_TLS_CLIENTCERT_FILE=$DATA/tls/$PEER_NAME-cli-client.crt
export CORE_PEER_TLS_CLIENTKEY_FILE=$DATA/tls/$PEER_NAME-cli-client.key
export CORE_PEER_PROFILE_ENABLED=true
# gossip variables
export CORE_PEER_GOSSIP_USELEADERELECTION=true
export CORE_PEER_GOSSIP_ORGLEADER=false
export ORDERER_PORT_ARGS=" -o orderer0.org0.deevo.com:7050 --tls --cafile $DATA/org0-ca-cert.pem --clientauth"
export ORDERER_CONN_ARGS="$ORDERER_PORT_ARGS --keyfile $CORE_PEER_TLS_CLIENTKEY_FILE --certfile $CORE_PEER_TLS_CLIENTCERT_FILE"
echo $ORDERER_CONN_ARGS

echo "Instantiating chaincode on $PEER_HOST ..."
export ORDERER_PORT_ARGS=" -o orderer0.org0.deevo.com:7050 --tls --cafile $DATA/org0-ca-cert.pem --clientauth"
export ORDERER_CONN_ARGS="$ORDERER_PORT_ARGS --keyfile $CORE_PEER_TLS_CLIENTKEY_FILE --certfile $CORE_PEER_TLS_CLIENTCERT_FILE"
POLICY="OR('org1MSP.member', 'org2MSP.member', 'org3MSP.member', 'org4MSP.member', 'org5MSP.member')"
$GOPATH/src/github.com/hyperledger/fabric/build/bin/peer chaincode instantiate -C $CHANNEL_NAME -n ${n} -v 1.0 -c '{"Args":["init"]}' -P "$POLICY" $ORDERER_CONN_ARGS

sleep 10

