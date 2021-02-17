variable tenancy_ocid {}
variable region {}
variable user_name {
    type = string
}
variable user_description {
    type = string
}
variable user_ocid {
    default = null
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
variable generate_cli_config {
    type = bool
}
variable generate_auth_token {
    type = bool
}
