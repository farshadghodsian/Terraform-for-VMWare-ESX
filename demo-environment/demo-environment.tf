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

resource "vsphere_virtual_machine" "web01" { 
  name             = "web01"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus = 2
  memory   = 1024
  guest_id = "centos7_64Guest"

  network_interface {
    network_id = "${data.vsphere_network.network.id}"
  }

  disk {
    label = "disk0"
    datastore_id = "${data.vsphere_datastore.datastore.id}"
    path = "/web01/web01.vmdk"
    attach = true
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.linux_password} | sudo -S hostname ${self.name}",
      "sudo yum update -y",
      "sudo yum install -y nano net-tools epel-release"
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

resource "vsphere_virtual_machine" "db01" {
  name             = "db01"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus = 2
  memory   = 2048
  guest_id = "centos7_64Guest"

  network_interface {
    network_id = "${data.vsphere_network.network.id}"
  }

  disk {
    label = "disk0"
    datastore_id = "${data.vsphere_datastore.datastore.id}"
    path = "/db01/db01.vmdk"
    attach = true
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.linux_password} | sudo -S hostname ${self.name}",
      "sudo yum update -y",
      "sudo yum install -y nano net-tools epel-release wget",
      "wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm",
      "sudo rpm -ivh mysql-community-release-el7-5.noarch.rpm",
      "sudo yum update -y",
      "sudo yum install -y mysql-server",
      "sudo systemctl start mysqld",
      "sudo systemctl enable mysqld"
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
resource "vsphere_virtual_machine_snapshot" "web01_init_snap" {
  depends_on=["vsphere_virtual_machine.web01"]
  virtual_machine_uuid = "${vsphere_virtual_machine.web01.id}"
  snapshot_name        = "Initial Provision"
  description          = "This is Demo Snapshot of when server was provisioned"
  memory               = "false"
  quiesce              = "false"
  remove_children      = "true"
  consolidate          = "true"
}


# To destroy a specific resource like the VM web02
# terraform destroy -target vsphere_virtual_machine.web02



###################
##    Outputs    ##
###################

output "web01_ip" {
  depends_on=["vsphere_virtual_machine.web01"]
  value = "${vsphere_virtual_machine.web01.default_ip_address}"
  description = "IP to access web01"
}

output "db01_ip" {
  depends_on=["vsphere_virtual_machine.db01"]
  value = "${vsphere_virtual_machine.db01.default_ip_address}"
  description = "IP to access db01"
}