## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output oci_config {
  value = var.generate_cli_config ? {
    user_ocid = var.user_ocid != null ? var.user_ocid : join("", oci_identity_user.user.*.id)
    tenancy_ocid = var.tenancy_ocid
    region = var.region
    private_key_path = local_file.private_key_file[0].filename
    fingerprint = oci_identity_api_key.api_key[0].fingerprint
  } : {}
}

output auth_token {
  value = var.generate_auth_token ? {
    username = "${data.oci_objectstorage_namespace.tenancy_namespace.namespace}/${var.user_ocid == null ? var.user_name : join("", oci_identity_user.user.*.name)}"
    token = oci_identity_auth_token.auth_token[0].token
  } : {}
}
