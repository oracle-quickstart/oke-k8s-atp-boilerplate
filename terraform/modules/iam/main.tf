# ## Copyright © 2021, Oracle and/or its affiliates. 
# ## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

module "group" {
  source = "../group"
  tenancy_ocid=var.tenancy_ocid
  group_ocid=var.user_ocid != null ? "notnull" : var.group_ocid
  group_name=var.group_name
  group_description=var.group_description
  policies=var.policies
}

module "user" {
  source = "../user"
  tenancy_ocid=var.tenancy_ocid
  user_ocid=var.user_ocid
  user_name=var.user_name
  user_description=var.user_description
  create_group_membership=var.user_ocid == null ? true : false
  # if group_ocid is provided, will create group memberships. Ignored if user_ocid is provided
  group_ocid=module.group.group_ocid
}

module "api_key" {
  source = "../api_key"
  user_ocid = module.user.user.id
  user_name = module.user.user.name
  generate_api_key = var.generate_oci_config
}

module "oci_config" {
  source = "../oci_config"
  tenancy_ocid = var.tenancy_ocid
  region = var. region
  key = module.api_key.key
  generate_oci_config = var.generate_oci_config
}

module "auth_token" {
  source = "../auth_token"
  user_ocid = module.user.user.id
  token_name = var.user_name
  auth_token = var.auth_token
  generate_auth_token = var.generate_docker_credentials
}

module "docker_credentials" {
  source = "../docker_credentials"
  tenancy_ocid = var.tenancy_ocid
  user_name = module.user.user.name
  auth_token = module.auth_token.auth_token
  generate_docker_credentials = var.generate_docker_credentials
}