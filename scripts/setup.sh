PLATFORM=$(uname)

# Install kubectl
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/${PLATFORM}/amd64/kubectl"
chmod +x ./kubectl
mv kubectl /usr/local/bin/kubectl
kubectl version --client

# Install kustomize

curl -s "https://raw.githubusercontent.com/\
kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
mv kustomize /usr/local/bin/kustomize
