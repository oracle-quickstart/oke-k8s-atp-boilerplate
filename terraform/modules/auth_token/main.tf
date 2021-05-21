## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_identity_auth_token" "auth_token" {
    count = var.generate_auth_token && var.auth_token == null ? 1 : 0
    #Required
    description = var.token_name
    user_id = var.user_ocid
}
