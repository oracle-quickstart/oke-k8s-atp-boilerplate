## Copyright (c) 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "region" {}
variable "cluster_id" {}

variable "ocir_pusher_ocid" {
    default = null
}
variable "ocir_pushers_group_ocid" {
    default = null
}
variable "ocir_pusher_auth_token" {
    default = null
}

variable "ci_user_ocid" {
    default = null
}
variable "ci_users_group_ocid" {
    default = null
}

variable "streaming_user_ocid" {
    default = null
}
variable "streaming_user_auth_token" {
    default = null
}
variable "streaming_group_ocid" {
    default = null
}
