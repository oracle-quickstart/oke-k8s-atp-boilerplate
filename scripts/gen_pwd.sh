## Copyright (c) 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

echo "You are about to replace the password for all the secrets. "
echo "You will need to delete and re-deploy the stack for changes to take effect."
echo "Continue? (y/N)"
read AGREE

BASEDIR=$(dirname "$0")
SECRETS_FOLDER=${BASEDIR}/../k8s/base/infra

PLATFORM=$(uname)
if [[ "$PLATFORM" == "linux" ]]; then
    BASE64_FLAG="-w"
else
    BASE64_FLAG="-b"
fi

function genpwd {
    # gen a 28 character random alphanum lower/upper password
    printf $(xxd -l 14 -p /dev/urandom | tr 'acegikmoqsuwy' 'ACEGIKMOQSUWY')
}

if [[ "$AGREE" == "y" ]]; then

    DB_ADMIN_PWD=$(genpwd)
    # DB_USER is hard coded in some queries so do not change or change in code too 
    DB_USER=demodata
    # restricted user.
    DB_USER_PWD=$(genpwd)
    # used only to get the wallet, not used by the user or any of the pods
    WALLET_PWD=$(genpwd)

    DB_USER_PWD_ENCODED=$(printf "${DB_USER_PWD}" | base64 ${BASE64_FLAG} 0)
    DB_ADMIN_PWD_ENCODED=$(printf "${DB_ADMIN_PWD}" | base64 ${BASE64_FLAG} 0)
    WALLET_PWD_ENCODED=$(printf "${WALLET_PWD}" | base64 ${BASE64_FLAG} 0)
    echo "Editing ${SECRETS_FOLDER}/atp-user.Secret.yaml"
    sed -i '' -e "s|  # DB_PWD: .*$|  # DB_PWD: ${DB_USER_PWD}|;" ${SECRETS_FOLDER}/atp-user.Secret.yaml
    sed -i '' -e "s|  DB_PWD: .*$|  DB_PWD: ${DB_USER_PWD_ENCODED}|;" ${SECRETS_FOLDER}/atp-user.Secret.yaml
    echo "Editing ${SECRETS_FOLDER}/atp-admin.Secret.yaml"
    sed -i '' -e "s|  # DB_ADMIN_PWD: .*$|  # DB_ADMIN_PWD: ${DB_ADMIN_PWD}|;" ${SECRETS_FOLDER}/atp-admin.Secret.yaml
    sed -i '' -e "s|  DB_ADMIN_PWD: .*$|  DB_ADMIN_PWD: ${DB_ADMIN_PWD_ENCODED}|;" ${SECRETS_FOLDER}/atp-admin.Secret.yaml
    sed -i '' -e "s|  # walletPassword: .*$|  # walletPassword: ${WALLET_PWD}|;" ${SECRETS_FOLDER}/atp-admin.Secret.yaml
    sed -i '' -e "s|  walletPassword: .*$|  walletPassword: ${WALLET_PWD_ENCODED}|;" ${SECRETS_FOLDER}/atp-admin.Secret.yaml

    DB_ADMIN_PWD_JSON=$(printf "{\"password\":\"${DB_ADMIN_PWD}\"}")
    WALLET_PWD_JSON=$(printf "{\"walletPassword\":\"${WALLET_PWD}\"}")
    DB_ADMIN_PWD_JSON_ENCODED=$(printf ${DB_ADMIN_PWD_JSON} | base64 ${BASE64_FLAG} 0)
    WALLET_PWD_JSON_ENCODED=$(printf ${WALLET_PWD_JSON} | base64 ${BASE64_FLAG} 0)
    echo "Editing ${SECRETS_FOLDER}/atp.Secret.yaml"
    sed -i '' -e "s|  # {\"password\":\".*\"}$|  # ${DB_ADMIN_PWD_JSON}|;" ${SECRETS_FOLDER}/atp.Secret.yaml
    sed -i '' -e "s|  password: .*$|  password: ${DB_ADMIN_PWD_JSON_ENCODED}|;" ${SECRETS_FOLDER}/atp.Secret.yaml
    sed -i '' -e "s|  # {\"walletPassword\":\".*\"}$|  # ${WALLET_PWD_JSON}|;" ${SECRETS_FOLDER}/atp.Secret.yaml
    sed -i '' -e "s|  walletPassword: .*$|  walletPassword: ${WALLET_PWD_JSON_ENCODED}|;" ${SECRETS_FOLDER}/atp.Secret.yaml

    echo "These passwords can be used to login to the ATP database:"
    echo "DB_ADMIN_PWD: ${DB_ADMIN_PWD}"
    echo "DB_USER_PWD: ${DB_USER_PWD}"
else
    echo "Aborted"
fi
