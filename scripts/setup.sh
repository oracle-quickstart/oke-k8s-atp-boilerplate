PLATFORM=$(uname)

# Install kubectl
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/${PLATFORM}/amd64/kubectl"
chmod +x ./kubectl

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

# Install kustomize

curl -s "https://raw.githubusercontent.com/\
kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
mv kustomize ${DEPS}/kustomize
