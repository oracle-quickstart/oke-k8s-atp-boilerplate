## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output key {
  value = var.generate_api_key ? {
    name = var.user_name
    user_ocid = var.user_ocid
    private_key_path = local_file.private_key_file[0].filename
    fingerprint = oci_identity_api_key.api_key[0].fingerprint
  } : {}
}
