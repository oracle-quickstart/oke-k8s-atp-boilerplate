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


resource "null_resource" "kafka_secret" {

    depends_on = [null_resource.cluster_kube_config]

    provisioner "local-exec" {
        command = templatefile("./templates/kafka-secret.tpl",
            {
                username = base64encode(module.streaming_user.docker_credentials.username)
                auth_token = base64encode(module.streaming_user.docker_credentials.token)
            })
    }
    provisioner "local-exec" {
        when = destroy
        command = "rm ../k8s/base/infra/kafka.Secret.yaml"
    }

}

resource "null_resource" "extract_ocir_secret" {

    depends_on = [null_resource.cluster_kube_config]

    provisioner "local-exec" {
        command = templatefile("./templates/ocir-secret.tpl", {})
    }
    provisioner "local-exec" {
        when = destroy
        command = "rm ../k8s/base/infra/ocir.Secret.yaml"
    }
}

resource "null_resource" "metric_server" {

    depends_on = [null_resource.cluster_kube_config]

    provisioner "local-exec" {
        command = "kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.4.1/components.yaml"
    }
    provisioner "local-exec" {
        when = destroy
        command = "kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.4.1/components.yaml"
        on_failure = continue
    }
}

resource "null_resource" "credsenv" {

    provisioner "local-exec" {
        # The # character needs to be escaped in the creds.env file as it is an include in the makefile and otherwise is taken as a comment.
        command = "printf 'TENANCY_NAMESPACE=${module.ocir_pusher.docker_credentials.tenancy_namespace}\nDOCKER_USERNAME=${module.ocir_pusher.docker_credentials.username}\nDOCKER_PASSWORD=${replace(module.ocir_pusher.docker_credentials.token, "/#/", "\\#")}\n' > ../creds.env"
    }
}

resource "null_resource" "globalenv" {

    provisioner "local-exec" {
        # edit the global.env file to match the region we're using
        command = "sed -i '' -e 's|OCIR_REGION=.*|OCIR_REGION=${var.region}|g' ../global.env"
    }
}

resource "null_resource" "streaming_compartment" {

    provisioner "local-exec" {
        # edit the streaming kubernetes manifest to inject the required compartment_ocid
        command = "sed -i '' -e 's|   compartmentId: .*|   compartmentId: ${var.compartment_ocid}|g' ../k8s/base/infra/streaming.ServiceInstance.yaml"
    }
}

resource "null_resource" "atp_compartment" {

    provisioner "local-exec" {
        # edit the streaming kubernetes manifest to inject the required compartment_ocid
        command = "sed -i '' -e 's|    compartmentId: .*|    compartmentId: ${var.compartment_ocid}|g' ../k8s/base/infra/atp.ServiceInstance.yaml"
    }
}