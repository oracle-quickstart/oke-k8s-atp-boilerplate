# ## Copyright © 2021, Oracle and/or its affiliates. 
# ## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_identity_group" "group" {
    # if group ocid was provided, don't create new group
    count = var.group_ocid == null ? 1 : 0

    compartment_id = var.tenancy_ocid
    description = var.group_description
    name = var.group_name
}

resource "oci_identity_policy" "policy" {
    # if the group_ocid was provided, assume the policy exists
    count = var.group_ocid == null ? length(var.policies) : 0

    depends_on = [oci_identity_group.group]
    compartment_id = var.tenancy_ocid
    description = var.policies[count.index].description
    name = var.policies[count.index].name
    statements = var.policies[count.index].statements
}
