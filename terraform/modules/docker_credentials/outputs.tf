## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output credentials {
  value = var.generate_docker_credentials ? {
    tenancy_namespace = data.oci_objectstorage_namespace.tenancy_namespace.namespace
    username = "${data.oci_objectstorage_namespace.tenancy_namespace.namespace}/${var.user_name}"
    token = var.auth_token
  } : {}
}
