## Automating Infrastructure provisioning on VMWare ESX with Terraform

Note this setup has been tested with the free version of VMWare ESX 6.7.

#### To create the Demo-Environment
First you will need to populate the <strong>terrform.tfvars</strong> file with the required server IP, as well as, username and passwords for your ESX Host and Linux servers.

Then cd into the demo-environment directory and initialize the terraform providers via the below command:<br />
<code>cd demo-environment</code><br />
<code>terraform init</code><br />

Next you can run the terraform plan command to review all the changes that will be performed:<br />
<code>terraform plan --var-file="..\terraform.tfvars" --out demo.plan</code>

After reviewing the plan you can apply it like so:<br />
<code>terraform apply demo.plan</code>

This should create 1 webservers and 1 database server in your demo environment.

<strong>Note:</strong> Becaue ESX doesn't support templates and making clones you will have to big a server image manually first in ESX. I chose a centos7 image to base my VM off of. You will also need to install vmtools on the VM you create as Terraform requires it be installed so that it can grab the network infromation such as IP from the server. Then you will have to copy the VMDK file to the following directorys:

/web01/web01.vmdk<br />
/db01/db01.vmdk

These vmdk files will be used to mount the disks when the VMs are created and it will save you the trouble of going through the OS install for all the VMs manually. You will only need to go through the OS install once for your inital VM you created. Then you would just copy the vmdk file to the above directories.

Again this is only for ESX as it does not support templates and cloning.


#### To view the outputs from your Terraform plan after the VMs have already been provisioned
<code>terraform output</code>

This should return a list of IPs for your newly created servers