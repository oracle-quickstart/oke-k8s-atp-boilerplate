## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "oci_identity_user" "user" {
    user_id = var.user_ocid == null ? join("", oci_identity_user.user.*.id) : var.user_ocid
}