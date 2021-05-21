## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output oci_config {
  value = module.oci_config.oci_config
}

output docker_credentials {
  value = module.docker_credentials.credentials
}

output auth_token {
  value = module.auth_token.auth_token
}
output user {
  value = module.user.user
}