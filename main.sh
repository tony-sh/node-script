#!/bin/bash
InfuraIDBeacon=""
InfuraIDECDSA=""
Wallet=""
JSONpass=""
keepwalletJSON=""
sudo ufw allow 22/tcp
sudo ufw allow 3919/tcp
sudo ufw allow 3920/tcp
sudo ufw enable
sudo apt-get update
sudo apt-get remove docker docker-engine docker.io
sudo apt install docker.io curl -y
sudo systemctl start docker
sudo systemctl enable docker
mkdir -p $HOME/keep-beacon/config
mkdir -p $HOME/keep-beacon/keystore
mkdir -p $HOME/keep-beacon/persistence
mkdir -p $HOME/keep-ecdsa/config
mkdir -p $HOME/keep-ecdsa/keystore
mkdir -p $HOME/keep-ecdsa/persistence
cat <<EOF >> $HOME/keep-beacon/config/config.toml
# Ethereum host connection info.
[ethereum]
 URL = "wss://ropsten.infura.io/ws/v3/$InfuraIDBeacon"
 URLRPC = "https://ropsten.infura.io/v3/$InfuraIDBeacon"
 
# Keep operator Ethereum account.
[ethereum.account]
 Address = "$Wallet"
 KeyFile = "/mnt/keystore/keep_wallet.json"
 
# Keep contract addresses configuration.
[ethereum.ContractAddresses]
 KeepRandomBeaconOperator = "0xC8337a94a50d16191513dEF4D1e61A6886BF410f"
 TokenStaking = "0x234d2182B29c6a64ce3ab6940037b5C8FdAB608e"
 KeepRandomBeaconService = "0x6c04499B595efdc28CdbEd3f9ed2E83d7dCCC717"
 
# Keep network configuration.
[LibP2P]
  Peers = ["/dns4/bootstrap-1.core.keep.test.boar.network/tcp/3001/ipfs/16Uiu2HAkuTUKNh6HkfvWBEkftZbqZHPHi3Kak5ZUygAxvsdQ2UgG",
"/dns4/bootstrap-2.core.keep.test.boar.network/tcp/3001/ipfs/16Uiu2HAmQirGruZBvtbLHr5SDebsYGcq6Djw7ijF3gnkqsdQs3wK","/dns4/bootstrap-3.test.keep.network/tcp/3919/ipfs/16Uiu2HAm8KJX32kr3eYUhDuzwTucSfAfspnjnXNf9veVhB12t6Vf","/dns4/bootstrap-2.test.keep.network/tcp/3919/ipfs/16Uiu2HAmNNuCp45z5bgB8KiTHv1vHTNAVbBgxxtTFGAndageo9Dp"]
Port = 3919
AnnouncedAddresses = ["/ip4/$SERVER_IP/tcp/3920"]
 
# Storage is encrypted
[Storage]
 DataDir = "/mnt/persistence"
EOF
cat <<EOF >> $HOME/keep-beacon/keystore/keep_wallet.json
$keepwalletJSON
EOF
cat <<EOF >> $HOME/keep-ecdsa/config/config.toml
[ethereum]
 URL = "wss://ropsten.infura.io/ws/v3/$InfuraIDECDSA" 
 URLRPC = "https://ropsten.infura.io/v3/$InfuraIDECDSA"
# Keep operator Ethereum account.
[ethereum.account]
 Address = "$Wallet"
 KeyFile = "/mnt/keep-ecdsa/keystore/keep_wallet.json"
# Addresses of contracts deployed on ethereum blockchain.
[ethereum.ContractAddresses]
 BondedECDSAKeepFactory = "0x9EcCf03dFBDa6A5E50d7aBA14e0c60c2F6c575E6"
# Addresses of applications approved by the operator.
[SanctionedApplications]
 Addresses = [
 "0xc3f96306eDabACEa249D2D22Ec65697f38c6Da69"
]
# Keep network configuration.
[LibP2P]
 Peers = ["/dns4/bootstrap-1.ecdsa.keep.test.boar.network/tcp/4001/ipfs/16Uiu2HAmPFXDaeGWtnzd8s39NsaQguoWtKi77834A6xwYqeicq6N",
"/dns4/ecdsa-2.test.keep.network/tcp/3919/ipfs/16Uiu2HAmNNuCp45z5bgB8KiTHv1vHTNAVbBgxxtTFGAndageo9Dp",
"/dns4/ecdsa-3.test.keep.network/tcp/3919/ipfs/16Uiu2HAm8KJX32kr3eYUhDuzwTucSfAfspnjnXNf9veVhB12t6Vf"]
Port = 3919
# Override the nodeРҐs default addresses announced in the network
 AnnouncedAddresses = ["/ip4/185.93.108.185/tcp/5678"]
# Storage is encrypted
[Storage]
 DataDir = "/mnt/keep-ecdsa/persistence"
[TSS]
EOF
cat <<EOF >> $HOME/keep-ecdsa/keystore/keep_wallet.json
$keepwalletJSON
EOF
export KEEP_CLIENT_ETHEREUM_PASSWORD="$JSONpass"
sudo docker run -dit \
--restart always \
--volume $HOME/keep-beacon:/mnt \
--env KEEP_ETHEREUM_PASSWORD=$KEEP_CLIENT_ETHEREUM_PASSWORD \
--env LOG_LEVEL=debug \
--name keep-beacon \
-p 3920:3919 \
keepnetwork/keep-client:v1.3.0-rc.4 --config /mnt/config/config.toml start
sudo docker run -d \
 --restart always \
 --entrypoint /usr/local/bin/keep-ecdsa \
 --volume $HOME/keep-ecdsa:/mnt/keep-ecdsa \
  --env KEEP_ETHEREUM_PASSWORD=$KEEP_CLIENT_ETHEREUM_PASSWORD \
 --env LOG_LEVEL=debug \
 --name keep-ecdsa \
 -p 3919:3919 \
 keepnetwork/keep-ecdsa-client:v1.2.0-rc.5 \
 --config /mnt/keep-ecdsa/config/config.toml start
