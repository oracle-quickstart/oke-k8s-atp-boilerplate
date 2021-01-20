## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

# Configure the cluster with kube-config

resource "null_resource" "cluster_kube_config" {
    provisioner "local-exec" {
        command = templatefile("./templates/cluster-kube-config.tpl",
            {
                cluster_id = var.cluster_id
                region = var.region
            })
    }
}

# grant CI user access to cluster
resource "null_resource" "ci_user_bind_cluster_admin_role" {

    depends_on = [null_resource.cluster_kube_config]

    provisioner "local-exec" {
        command = "kubectl create clusterrolebinding ${local.ci_user_name} --clusterrole=cluster-admin --user=${module.ci_user.oci_config.user_ocid}"
    }
}
