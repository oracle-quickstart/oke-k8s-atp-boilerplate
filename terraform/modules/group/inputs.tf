variable tenancy_ocid {}
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
