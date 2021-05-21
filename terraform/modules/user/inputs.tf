## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable tenancy_ocid {}
variable user_ocid {
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
variable create_group_membership {
    type = bool
}