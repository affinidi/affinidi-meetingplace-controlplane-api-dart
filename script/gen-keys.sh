#!/bin/zsh

# -x Print out all executed commands to the terminal.
# set -x
# -e  Exit immediately if a command exits with a non-zero status.
set -e

mkdir -p ./keys
openssl ecparam -name secp256k1 -genkey -noout -out ./keys/secp256k1.pem
openssl ecparam -name prime256v1 -genkey -noout -out ./keys/p256.pem

openssl genpkey -algorithm Ed25519 -out ./keys/ed25519.pem
openssl pkey -in keys/ed25519.pem -pubout -out ./keys/ed25519-pub.pem

mkdir -p ./secrets
mkdir -p ./params
dart pub get
dart run script/setup.dart
