
This project accomplishes the following tasks:

Implements an Azure policy that enforces the necessity of tagging resources before creation within the subscription.
Utilizes Packer to construct a virtual machine template hosting a website showcasing the iconic message, 'Hello World!'
Employs Terraform to provision an array of essential resources within the Azure environment, including:

Availability sets
OS disks
Data disks
Load balancers
Network interfaces
Network security groups
Public IP addresses
Virtual Machines
Virtual Networks

Operational Guidelines

**Deploying the Policy**
Begin by crafting the policy definition:
```
az policy definition create --name tagging-policy --mode indexed --rules tagging-policy.json
```


Then, assign the policy definition as follows:

```
az policy assignment create --policy tagging-policy --name tagging-policy
```

**Create a Image Packer**


Firstly, log in to Azure:
```
az login
```

Before executing Packer, set up a resource group to encapsulate all the resources:
```
az group create -n Azuredevops -l eastus
```
Create a service principal to enable Packer to create templates in Azure:
```
az ad sp create-for-rbac --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"
```

On the machine you are operating Packer from, establish the following environment variables using the output from the aforementioned command, in addition to your subscription ID:

CLIENT_ID
CLIENT_SECRET
TENANT_ID
SUBSCRIPTION_ID


Customize the subsequent values in server.json:

managed_image_resource_group_name - The name of the resource group you created in azure
managed_image_name - The name to give to your template
os_type - The OS type of the base image
image_publisher - The publisher of the base image
image_offer - The offer of the base image
image_sku - The SKU of the base image
location - The region of the image
vm_size - The size of the VM
azure_tags:
environment: Environment tag,
provisioners:
inline - The commands to execute on your template

Generate the packer image in Azure:
```
packer build server.json
```

**Resource Provisioning via Terraform**
Commence by downloading the necessary plugins:
```
terraform init
```

To tailor the deployment, edit the variables in the terraform.tfvars file, affecting the following settings:

prefix - Prefix for all resource names
location - Azure region for deployment (East US)
username - VMs' admin username
password - VMs' admin password
environment - Environment tag, e.g., prod, dev
server_names - name of VMs
packerImageId - Id of packer image create before
vm_count - the number of VM

Execute resource provisioning:

```
terraform plan -out solution.plan
```
```
terraform apply "solution.plan"
```

When your resources are no longer required, delete them as follows:

```
terraform destroy
```

Finally, you can remove the resource group:

```
az group delete -n phongmx-rg
```