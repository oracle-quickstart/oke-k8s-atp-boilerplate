## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output auth_token {
  value = var.generate_auth_token ? (var.auth_token == null ? oci_identity_auth_token.auth_token[0].token : var.auth_token) : ""
}
