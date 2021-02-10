variable "tenancy_ocid" {}
variable "region" {}
variable "cluster_id" {} 
variable "ocir_pushers_group_ocid" {
    default = null
}
variable "ci_user_group_ocid" {
    default = null
}
variable "streaming_group_ocid" {
    default = null
}