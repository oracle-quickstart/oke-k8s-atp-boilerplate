# ## Copyright © 2021, Oracle and/or its affiliates. 
# ## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_identity_user" "user" {
    count = var.user_ocid == null ? 1 : 0

    compartment_id = var.tenancy_ocid
    description = var.user_description
    name = var.user_name
}

resource "oci_identity_user_group_membership" "membership" {
    count = var.create_group_membership ? 1 : 0

    group_id = var.group_ocid
    user_id = join("", oci_identity_user.user.*.id)
}
