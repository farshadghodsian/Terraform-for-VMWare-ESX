###################################
##    VMWare VSphere Provider    ##
###################################

provider "vsphere" {
  user           = "${var.vsphere_user}"
  password       = "${var.vsphere_password}"
  vsphere_server = "${var.vsphere_server}"
  # If you have a self-signed cert
  allow_unverified_ssl = true
}

###########################
##    Data References    ##
###########################
data "vsphere_datacenter" "dc" {
  name = "dc1"
}

data "vsphere_datastore" "datastore" {
  name          = "datastore1"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
  name          = "cluster1/Resources"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}



#############################
##    VM Infrastructure    ##
#############################

resource "vsphere_file" "centos7_flat_copy" {
   source_datacenter = "${data.vsphere_datacenter.dc.id}"
   datacenter        = "${data.vsphere_datacenter.dc.id}"
   source_datastore  = "${data.vsphere_datastore.datastore.name}"
   datastore         = "${data.vsphere_datastore.datastore.name}"
   source_file       = "/templates/centos7x64-flat.vmdk"
   destination_file  = "/elk01/centos7x64-flat.vmdk"
   create_directories = true
 }

resource "vsphere_file" "centos7_vmdk_copy" {
   depends_on=["vsphere_file.centos7_flat_copy"]
   source_datacenter = "${data.vsphere_datacenter.dc.id}"
   datacenter        = "${data.vsphere_datacenter.dc.id}"
   source_datastore  = "${data.vsphere_datastore.datastore.name}"
   datastore         = "${data.vsphere_datastore.datastore.name}"
   source_file       = "/templates/vmdk/centos7x64.vmdk"
   destination_file  = "/elk01/elk01.vmdk"
   #create_directories = true
 }

resource "vsphere_virtual_machine" "elk01" {
  depends_on=["vsphere_file.centos7_vmdk_copy"]
  name             = "elk01"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus = 2
  memory   = 4096
  guest_id = "centos7_64Guest"

  network_interface {
    network_id = "${data.vsphere_network.network.id}"
  }

#  Unfortunately Cloning and setting IP addresses requires VCenter and wont work with ESX  
#  IP addresses can still be set on DNS server 
#  clone {
#     template_uuid = "${vsphere_virtual_machine.web01.uuid}"
#     customize {
#       network_interface {
#         ipv4_address = "192.168.1.103"
#         ipv4_netmask = 24
#       }
#       ipv4_gateway = "192.168.1.1"
#     }
#   }

  disk {
    label = "disk0"
    datastore_id = "${data.vsphere_datastore.datastore.id}"
    path = "/elk01/elk01.vmdk"
    attach = true
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.linux_password} | sudo -S hostname ${self.name}",
      "sudo yum update -y",
      "sudo yum install -y nano net-tools epel-release wget",
      "sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch",
      "wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.6.1.rpm",
      "wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.6.1.rpm.sha512",
      "sudo yum install -y perl-Digest-SHA-5.85-4.el7.x86_64 java-1.8.0-openjdk",
      "export JAVA_HOME=$(readlink -f /usr/bin/java | sed 's:/bin/java::')",
      "shasum -a 512 -c elasticsearch-6.6.1.rpm.sha512",
      "sudo rpm --install elasticsearch-6.6.1.rpm"

    ]
 
    connection {
      type     = "ssh"
      user     = "${var.linux_user}"
      password = "${var.linux_password}"
      timeout = "1m"
    } 

  }
  cdrom {
    datastore_id = "${data.vsphere_datastore.datastore.id}"
    path         = "iso/CentOS-7-x86_64-Minimal-1804.iso"
  }
}


####################
##   Snapshots    ##
####################
# resource "vsphere_virtual_machine_snapshot" "elk01_init_snap" {
#   depends_on=["vsphere_virtual_machine.elk01"]
#   virtual_machine_uuid = "${vsphere_virtual_machine.web01.id}"
#   snapshot_name        = "Initial Provision"
#   description          = "This is Demo Snapshot of when server was provisioned"
#   memory               = "false"
#   quiesce              = "false"
#   remove_children      = "true"
#   consolidate          = "true"
# }


# To destroy a specific resource like the VM elk01
# terraform destroy -target vsphere_virtual_machine.elk01



###################
##    Outputs    ##
###################

output "elasticsearch_url" {
  depends_on=["vsphere_virtual_machine.elk01"]
  value = "http://${vsphere_virtual_machine.elk01.default_ip_address}:9200"
  description = "URL to access elasticsearch on elk01"
}

output "logstash_url" {
  depends_on=["vsphere_virtual_machine.elk01"]
  value = "${vsphere_virtual_machine.elk01.default_ip_address}:5043"
  description = "IP and port that logstash will listen to on elk01"
}

output "kibana_url" {
  depends_on=["vsphere_virtual_machine.elk01"]
  value = "http://${vsphere_virtual_machine.elk01.default_ip_address}:5601"
  description = "URL to access kibana on elk01"
}
