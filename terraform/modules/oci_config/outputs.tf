## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output oci_config {
  value = var.generate_oci_config ? {
    user_ocid = var.key.user_ocid
    tenancy_ocid = var.tenancy_ocid
    region = var.region
    private_key_path = var.key.private_key_path
    fingerprint = var.key.fingerprint
  } : {}
}
