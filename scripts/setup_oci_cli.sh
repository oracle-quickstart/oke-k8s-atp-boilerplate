## Copyright (c) 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

# download OCI CLI
which oci \
|| curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh > install.sh \
&& chmod +x install.sh \
&& ./install.sh --accept-all-defaults

mkdir -p ~/.oci
export DEPS=${HOME}/deps
export PATH=$PATH:~/bin/:$DEPS

# save secrets to file
# CI user private key for OCI CLI
if [[ ! -z ${CI_USER_KEY+x} ]]; then
    echo "${CI_USER_KEY}" > ./cluster_admin_rsa_private_key.pem
    chmod 600 ./cluster_admin_rsa_private_key.pem
fi

# OCI CLI config file
if [[ ! -f ~/.oci/config ]]; then
    echo "${OCI_CONFIG}" > ~/.oci/config
    chmod 600 ~/.oci/config
fi

# cluster kubeconfig
if [[ ! -z ${KUBE_CONFIG_SECRET+x} ]]; then
    echo "${KUBE_CONFIG_SECRET}" > ./kube_config
fi
