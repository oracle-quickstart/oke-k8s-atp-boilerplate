
# random integer id suffix for the users
resource "random_integer" "random" {
  min = 1
  max = 100
}

locals {
    cluster_idx = substr(md5(var.cluster_id), 0, 4)
    idx = random_integer.random.result
    user_idx = "${local.cluster_idx}_${local.idx}"
    ci_user_name = "cluster_admin_user_${local.user_idx}"
    ci_user_description = "cluster-admin user ${random_integer.random.result} for ${var.cluster_id}"
    ci_group_name = "cluster_admin_users_${local.cluster_idx}"
    ci_group_description = "cluster_admin users for ${var.cluster_id}"
    ocir_pusher_user_name = "ocir_pusher_${local.user_idx}"
    ocir_pusher_user_description = "OCIR pusher user for ${var.cluster_id}"
    ocir_pusher_group_name = "ocir_pushers_${local.idx}"
    ocir_pusher_group_description = "OCIR pusher users ${local.idx}"
}