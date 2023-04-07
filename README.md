# Distrans Ifrastructure as Code (IaC) Repo
## **Setting up Azure VM self-hosted agent for distrans microservices**

The folder *distrans_pipelines* contains **Terraform** and **Ansible** files to setup a Azure VM self-hosted agent to be use with Azure DevOps Pipelines.

The terraform project on *distrans_pipelines/terraform* creates a Azure VM with a public IP and network rules to allow SSH and HTTPS connections. Also creates a Azure Container Registry to store the docker images created on the pipeline

### **Important input variables for terraform**
|Variable Name|Description|
|-------------|-----------|
|azurerm_resource_group_name| To specify the Azure Resource group where the resource are gonna be created|
|azurerm_location| The Azure's location where the resources are goona be created|

### **Using terraform**

First log in in your azure account using a tool like azure-cli and the run command from *distrans_pipelines/terraform* directory with your custom input values to generate a terraform plan:

`terraform plan -var azurerm_resource_group_name="1-d2083c39-playground-sandbox" -var azurerm_location="westus" --out plan`

then run:

`terraform apply --auto-approve plan`

to apply the change from the generated plan file and create the resources

### **Important output variables for terraform**
|Variable Name|Description|
|-------------|-----------|
|agent_public_ip_address| The public IP of the VM created|
|tls_private_key| TLS private key from VM to use to allow connection to the VM using secure shell|
|acr_admin_password| The password of the Azure Container Regustry|

**Notes** 
* Use command `terraform output -raw tls_private_key > id_rsa` to save a file with the private key to connect through ssh using `ssh -i id_rsa mv_user@agent_public_ip_address` (you must change the **id_rsa** file permission to 600 in order to work)
* Use command `terraform output -raw acr_admin_password` to get Azure Container Registry password