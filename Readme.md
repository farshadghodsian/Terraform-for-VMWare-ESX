## Automating Infrastructure provisioning on VMWare ESX with Terraform

Note this setup has been tested with the free version of VMWare ESX 6.7.

#### To create the Demo-Environment
First you will need to populate the <strong>terrform.tfvars</strong> file with the required server IP, as well as, username and passwords for your ESX Host and Linux servers.

Then cd into the demo-environment directory and initialize the terraform providers via the below command (input=false will force an error if user input is required instead of getting stuck forever):<br />
<code>cd demo-environment</code><br />
<code>terraform init -input=false</code><br />

Next you can run the terraform plan command to review all the changes that will be performed:<br />
<code>terraform plan --var-file="..\terraform.tfvars" --out demo.plan</code>

After reviewing the plan you can apply it like so:<br />
<code>terraform apply demo.plan</code>

This should create 1 webservers and 1 database server in your demo environment.

<strong>Note:</strong> Becaue ESX doesn't support templates and making clones you will have to build a server image manually first in ESX. I choose a centos7 image to base my VM off of. You will also need to install vmtools on the VM you create as Terraform requires it be installed so that it can grab the network information such as IP from the server. Then you will have to download the VMDK file to your PC so that it splits the file into a .vmdk file and a flat.vmdk file and then reupload them back to ESX (trying to do a copy without doing this first will fail in Terraform).

If done correctly this should allow you to copy of this VM if it were a Template and use the copied vmdk files to mount when the new VMs are created. This will save you the trouble of going through the OS install for all the VMs manually. You will only need to go through the OS install once for your inital VM you created. Then Terraform will just copy the vmdk files for each new VM.

Again this is only for ESX as it does not support templates and cloning.

For convinience I have included a Centos7 (x64) base vm and the required vmdk and flat.vmdk files for you if you dont want to go through the above hassle. Extract the Centos7x64.zip file and upload it to your datastore in the follow directories:

/templates/centos7x64-flat.vmdk
/templates/vmdk/centos7x64.vmdk

If the two files are in the same directory VMware will merge the two files and it will cause your later file copies to fail.

#### To view the outputs from your Terraform plan after the VMs have already been provisioned
<code>terraform output</code>

This should return a list of IPs for your newly created servers