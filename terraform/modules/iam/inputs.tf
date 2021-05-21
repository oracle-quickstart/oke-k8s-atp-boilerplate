variable tenancy_ocid {}
variable region {}
variable user_ocid {
    default = null
}
variable auth_token {
    default = null
}
variable user_name {
    type = string
}
variable user_description {
    type = string
}
variable group_ocid {
    default = null
}
variable group_name {
    type = string
}
variable group_description {
    type = string
}
variable policies {
    type = list(any)
}
variable generate_oci_config {
    type = bool
}
variable generate_docker_credentials {
    type = bool
}
