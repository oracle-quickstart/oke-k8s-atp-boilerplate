## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output "group_ocid" {
  value = var.group_ocid == null ? join("",oci_identity_group.group.*.id) : var.group_ocid
}