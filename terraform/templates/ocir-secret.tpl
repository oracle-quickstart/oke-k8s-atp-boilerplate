CONFIG=$(kubectl get secret -n default ocir-secret -o yaml \
| grep "  .dockerconfigjson:" \
| awk '{print $2}')

cat > ../k8s/base/infra/ocir.Secret.yaml << EOF
apiVersion: v1
data:
  .dockerconfigjson: $CONFIG
kind: Secret
metadata:
  name: ocir-secret
type: kubernetes.io/dockerconfigjson
EOF