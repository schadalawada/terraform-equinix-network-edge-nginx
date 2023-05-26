data "equinix_network_device_type" "this" {
  name = "Nginx"
}

data "equinix_network_device_platform" "this" {
  device_type = data.equinix_network_device_type.this.code
  flavor      = var.platform
}

data "equinix_network_device_software" "this" {
  device_type = data.equinix_network_device_type.this.code
  packages    = [var.software_package]
  stable      = true
  most_recent = true
}

resource "equinix_network_device" "this" {
  lifecycle {
    ignore_changes = [version, core_count]
  }
  self_managed           = true
  name                   = var.name
  hostname               = var.hostname
  type_code              = data.equinix_network_device_type.this.code
  package_code           = var.software_package
  version                = data.equinix_network_device_software.this.version
  core_count             = data.equinix_network_device_platform.this.core_count
  metro_code             = var.metro_code
  account_number         = var.account_number
  term_length            = var.term_length
  interface_count        = var.interface_count
  notifications          = var.notifications
  mgmt_acl_template_uuid = var.mgmt_acl_template_uuid != "" ? var.mgmt_acl_template_uuid : null
  additional_bandwidth   = var.additional_bandwidth > 0 ? var.additional_bandwidth : null
  ssh_key {
    username = var.ssh_key.userName
    key_name = var.ssh_key.keyName
  }

  dynamic "secondary_device" {
    #HA pair not supported for cluster device
    for_each = var.secondary.enabled && !var.cluster.enabled ? [1] : []
    content {
      name                   = "${var.name}-secondary"
      hostname               = var.secondary.hostname
      metro_code             = var.secondary.metro_code
      account_number         = var.secondary.account_number
      notifications          = var.notifications
      mgmt_acl_template_uuid = try(var.secondary.mgmt_acl_template_uuid, null)
      ssh_key {
        username = var.ssh_key.userName
        key_name = var.ssh_key.keyName
      }
    }
  }

  dynamic "cluster_details" {
    for_each = var.cluster.enabled ? [1] : []
    content {
      cluster_name = var.cluster.name

      node0 {
        vendor_configuration {
          hostname = var.cluster.node0_vendor_configuration_hostname
        }
      }
      node1 {
        vendor_configuration {
          hostname = var.cluster.node1_vendor_configuration_hostname
        }
      }
    }
  }
}

