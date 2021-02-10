## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

# if [[ ! $(kubectl get secret kafka-secret -n default) ]]; then
#     kubectl create secret generic kafka-secret \
#     -n default \
#     --from-literal=USERNAME=${username} \
#     --from-literal=KAFKA_PASSWORD="${auth_token}"
# fi 

cat > ../k8s/base/infra/kafka.Secret.yaml << EOF
apiVersion: v1
data:
  KAFKA_PASSWORD: ${auth_token}
  USERNAME: ${username}
kind: Secret
metadata:
  name: kafka-secret
type: Opaque
EOF