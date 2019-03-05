variable "vsphere_user" {
description = "VMWare vSphere user"
} # vsphere_password = ""

variable "vsphere_server" {
description= "VMWare vSphere server host IP"
}
variable "vsphere_password" {
    description = "vSphere password"
}
variable "linux_user" {
    description = "User used to execute commands on linux VMs"
}

variable "linux_password" {
    description = "Password for Linux User"
}
