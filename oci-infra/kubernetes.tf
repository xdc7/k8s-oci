# Create the Kubernetes cluster
resource "oci_containerengine_cluster" "k8s_cluster" {
  compartment_id     = var.compartment_id
  kubernetes_version = "${var.kubernetes_version}"
  name               = "free-k8s-cluster"
  vcn_id             = module.vcn.vcn_id
  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.vcn_public_subnet.id
  }
  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
    service_lb_subnet_ids = [oci_core_subnet.vcn_public_subnet.id]
  }
}

# Data source for getting availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

# Container node pool
resource "oci_containerengine_node_pool" "k8s_node_pool" {
  cluster_id         = oci_containerengine_cluster.k8s_cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = "${var.kubernetes_version}"
  name               = "free-k8s-node-pool"
  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.vcn_private_subnet.id
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[1].name
      subnet_id           = oci_core_subnet.vcn_private_subnet.id
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[2].name
      subnet_id           = oci_core_subnet.vcn_private_subnet.id
    }
    size = 2
  }
  node_shape = "VM.Standard.A1.Flex"
  node_shape_config {
    memory_in_gbs = 6
    ocpus         = 1
  }
  node_source_details {
    image_id    = "ocid1.image.oc1.iad.aaaaaaaac6jy4yovh7u6k7qguocu2wroyllwybfro6cir5mz5lsfdy7gg2cq"
    source_type = "image"
  }
  initial_node_labels {
    key   = "name"
    value = "free-k8s-cluster"
  }
  ssh_public_key = var.ssh_public_key
}