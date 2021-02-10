## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl


# OCI user with k8s cluster admin role for CI to deploy 
module "ci_user" {
    source = "./modules/iam"
    tenancy_ocid = var.tenancy_ocid
    region = var.region
    user_description = local.ci_user_description
    user_name = local.ci_user_name
    group_ocid = var.ci_user_group_ocid
    group_description = local.ci_group_description
    group_name = local.ci_group_name
    policies = [{
                    name = "cluster_admin_policy"
                    description = "cluster admins policy"
                    statements = [
                        "allow group ${local.ci_group_name} to use clusters in tenancy where request.region = '${var.region}'"
                    ]
                }]
    generate_cli_config = true
    generate_auth_token = false
}

# OCI Registry docker loging credentials for CI to push images to registry
module "ocir_pusher" {
    source = "./modules/iam"
    tenancy_ocid = var.tenancy_ocid
    region = var.region
    user_description = local.ocir_pusher_user_description
    user_name = local.ocir_pusher_user_name
    group_ocid = var.ocir_pushers_group_ocid
    group_description = local.ocir_pusher_group_description
    group_name = local.ocir_pusher_group_name
    policies = [{
                    description = "OCIR pushers user policy"
                    name = "OCIR_pushers_policy_${local.idx}"
                    statements = [
                        "allow group ${local.ocir_pusher_group_name} to use repos in tenancy",
                        "allow group ${local.ocir_pusher_group_name} to manage repos in tenancy where ANY {request.permission = 'REPOSITORY_CREATE', request.permission = 'REPOSITORY_UPDATE'}"
                    ]                
                }]
    generate_cli_config = false
    generate_auth_token = true
}

# credentials for streaming service user
module "streaming_user" {
    source = "./modules/iam"
    tenancy_ocid = var.tenancy_ocid
    region = var.region
    user_description = local.streaming_user_description
    user_name = local.streaming_user_name
    group_ocid = var.streaming_group_ocid
    group_description = local.streaming_group_description
    group_name = local.streaming_group_name
    policies = [{
                    description = "Streaming user policy"
                    name = "streamin_users_policy_${local.idx}"
                    statements = [
                        "allow group ${local.streaming_group_name} to use stream-pull in tenancy",
                        "allow group ${local.streaming_group_name} to use stream-push in tenancy"
                    ]                
                }]
    generate_cli_config = false
    generate_auth_token = true
}