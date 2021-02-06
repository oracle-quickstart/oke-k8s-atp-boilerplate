#!/bin/bash

PLATFORM=$(uname)

# Install kubectl
which kubectl \
|| curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/${PLATFORM}/amd64/kubectl" \
&& chmod +x ./kubectl

echo "Home is here: $HOME"

if $CI; then
    export DEPS=${HOME}/deps
    mkdir -p $DEPS
    export PATH=$PATH:$DEPS
else
    export DEPS=/usr/local/bin
fi
mv kubectl ${DEPS}/kubectl
kubectl version --client
