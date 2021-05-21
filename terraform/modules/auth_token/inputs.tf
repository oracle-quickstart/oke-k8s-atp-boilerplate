## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable user_ocid {
    default = null
}
variable auth_token {
    default = null
}
variable token_name {
    type = string
}
variable generate_auth_token {
    type = bool
}
