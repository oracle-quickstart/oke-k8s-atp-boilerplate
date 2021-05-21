# ## Copyright © 2021, Oracle and/or its affiliates. 
# ## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "tls_private_key" "private_key" {
  count = var.generate_api_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private_key_file" {
  count = var.generate_api_key ? 1 : 0
  filename          = "./${replace(var.user_name, "/", "-")}_rsa_private_key.pem"
  sensitive_content = tls_private_key.private_key[0].private_key_pem
}

resource "oci_identity_api_key" "api_key" {
  count = var.generate_api_key ? 1 : 0
  user_id   =  var.user_ocid
  key_value = tls_private_key.private_key[0].public_key_pem
}
