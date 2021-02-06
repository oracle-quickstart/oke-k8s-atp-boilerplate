#!/bin/bash

PLATFORM=$(uname)

echo "Home is here: $HOME"
echo "Platform: $PLATFORM"

if $CI; then
    export DEPS=${HOME}/deps
    mkdir -p $DEPS
    export PATH=$PATH:$DEPS
else
    export DEPS=/usr/local/bin
fi

# Install kubectl if not present
which kubectl \
|| (curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/${PLATFORM}/amd64/kubectl" \
&& install kubectl ${DEPS} \
&& echo "kubectl installed")

kubectl version --client


# Install kustomize if not present
which kustomize \
|| (curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash  \
&& echo "kustomize installed")

kustomize version 


# Install Skaffold if not present
which skaffold \
|| (curl -sLo skaffold "https://storage.googleapis.com/skaffold/releases/latest/skaffold-${PLATFORM,,}-amd64" \
&& sudo install skaffold /usr/local/bin \
&& echo "Skaffold instaled")

skaffold version
