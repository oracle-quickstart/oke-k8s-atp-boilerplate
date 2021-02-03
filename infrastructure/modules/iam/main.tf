# ## Copyright © 2021, Oracle and/or its affiliates. 
# ## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_identity_user" "user" {
    compartment_id = var.tenancy_ocid
    description = var.user_description
    name = var.user_name
}

resource "oci_identity_group" "group" {
    # if group ocid was provided, don't create new group
    count = var.group_ocid == null ? 1 : 0
    compartment_id = var.tenancy_ocid
    description = var.group_description
    name = var.group_name
}

resource "oci_identity_user_group_membership" "membership" {
    group_id = var.group_ocid != null ? var.group_ocid : join("", oci_identity_group.group.*.id)
    user_id = oci_identity_user.user.id
}

resource "oci_identity_policy" "policy" {
    # if the group_ocid was provided, assume the policy exists
    count = var.group_ocid == null ? 1 : 0
    depends_on = [oci_identity_group.group]
    compartment_id = var.tenancy_ocid
    description = var.policies[count.index].description
    name = var.policies[count.index].name
    statements = var.policies[count.index].statements
}

resource "tls_private_key" "private_key" {
  count = var.generate_cli_config ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private_key_file" {
  count = var.generate_cli_config ? 1 : 0
  filename          = "./${var.user_name}_rsa_private_key.pem"
  sensitive_content = tls_private_key.private_key[0].private_key_pem
}

resource "oci_identity_api_key" "api_key" {
  count = var.generate_cli_config ? 1 : 0
  user_id   =  oci_identity_user.user.id
  key_value = tls_private_key.private_key[0].public_key_pem
}

resource "local_file" "oci_config_file" {
  count = var.generate_cli_config ? 1 : 0
  filename          = "./${var.user_name}_oci_config.txt"
  content = templatefile("./templates/oci_config.tpl", {
    fingerprint = oci_identity_api_key.api_key[0].fingerprint
    user_ocid = oci_identity_user.user.id
    private_key_path = local_file.private_key_file[0].filename
    tenancy_ocid = var.tenancy_ocid
    region = var.region
  })
}

resource "oci_identity_auth_token" "auth_token" {
    count = var.generate_auth_token ? 1 : 0
    #Required
    description = "Auth Token"
    user_id = oci_identity_user.user.id
}
