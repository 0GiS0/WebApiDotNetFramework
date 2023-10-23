resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "${random_pet.prefix.id}-rg"
}

# # Create virtual network
# resource "azurerm_virtual_network" "my_terraform_network" {
#   name                = "${random_pet.prefix.id}-vnet"
#   address_space       = ["10.0.0.0/16"]
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
# }

# # Create subnet
# resource "azurerm_subnet" "my_terraform_subnet" {
#   name                 = "${random_pet.prefix.id}-subnet"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.my_terraform_network.name
#   address_prefixes     = ["10.0.1.0/24"]
# }

# # Create public IPs
# resource "azurerm_public_ip" "my_terraform_public_ip" {
#   name                = "${random_pet.prefix.id}-public-ip"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Dynamic"
# }

# # Create Network Security Group and rules
# resource "azurerm_network_security_group" "my_terraform_nsg" {
#   name                = "${random_pet.prefix.id}-nsg"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name

#   security_rule {
#     name                       = "RDP"
#     priority                   = 1000
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "*"
#     source_port_range          = "*"
#     destination_port_range     = "3389"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "web"
#     priority                   = 1001
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "80"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
# }

# # Create network interface
# resource "azurerm_network_interface" "my_terraform_nic" {
#   name                = "${random_pet.prefix.id}-nic"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name

#   ip_configuration {
#     name                          = "my_nic_configuration"
#     subnet_id                     = azurerm_subnet.my_terraform_subnet.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
#   }
# }

# # Connect the security group to the network interface
# resource "azurerm_network_interface_security_group_association" "example" {
#   network_interface_id      = azurerm_network_interface.my_terraform_nic.id
#   network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
# }

# # Create storage account for boot diagnostics
# resource "azurerm_storage_account" "my_storage_account" {
#   name                     = "diag${random_id.random_id.hex}"
#   location                 = azurerm_resource_group.rg.location
#   resource_group_name      = azurerm_resource_group.rg.name
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
# }


# # Create virtual machine
# resource "azurerm_windows_virtual_machine" "main" {
#   name                  = "${var.prefix}-vm"
#   admin_username        = "azureuser"
#   admin_password        = random_password.password.result
#   location              = azurerm_resource_group.rg.location
#   resource_group_name   = azurerm_resource_group.rg.name
#   network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
#   size                  = "Standard_DS1_v2"

#   os_disk {
#     name                 = "myOsDisk"
#     caching              = "ReadWrite"
#     storage_account_type = "Premium_LRS"
#   }

#   source_image_reference {
#     publisher = "MicrosoftWindowsServer"
#     offer     = "WindowsServer"
#     sku       = "2022-datacenter-azure-edition"
#     version   = "latest"
#   }


#   boot_diagnostics {
#     storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
#   }
# }

# # Install IIS web server to the virtual machine
# resource "azurerm_virtual_machine_extension" "web_server_install" {
#   name                       = "${random_pet.prefix.id}-wsi"
#   virtual_machine_id         = azurerm_windows_virtual_machine.main.id
#   publisher                  = "Microsoft.Compute"
#   type                       = "CustomScriptExtension"
#   type_handler_version       = "1.8"
#   auto_upgrade_minor_version = true

#   settings = <<SETTINGS
#     {
#       "commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"
#     }
#   SETTINGS
# }

# Create an Azure Container App in the same vnet to execute GitHub runners
# Create Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "${replace(random_pet.prefix.id, "-", "")}acr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Create ACR task
resource "azurerm_container_registry_task" "acr_task" {
  name                  = "generate-gh-runner"
  container_registry_id = azurerm_container_registry.acr.id

  platform {
    os = "Linux"
  }

  docker_step {
    dockerfile_path      = "Dockerfile.github"
    context_path         = "https://github.com/Azure-Samples/container-apps-ci-cd-runner-tutorial.git"
    context_access_token = var.gh_pat
    image_names          = ["github-actions-runner:1.0"]
  }

  provisioner "local-exec" {
    # Execute ACR task
    command = "az acr task run --registry ${azurerm_container_registry.acr.name} --name ${azurerm_container_registry_task.acr_task.name}"
  }
}



# Execute ACR task
resource "azurerm_container_registry_task_schedule_run_now" "task_run" {
  depends_on                 = [azurerm_container_registry_task.acr_task]
  container_registry_task_id = azurerm_container_registry_task.acr_task.id
}

# https://learn.microsoft.com/en-us/azure/container-apps/tutorial-ci-cd-runners-jobs?tabs=bash&pivots=container-apps-jobs-self-hosted-ci-cd-github-actions
resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "${random_pet.prefix.id}-workspace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


resource "azurerm_container_app_environment" "aca_env" {
  name                       = "${random_pet.prefix.id}-aca-env"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id
}

resource "azapi_resource" "gh_runner_aca" {

  depends_on = [azurerm_container_registry_task.acr_task]

  type      = "Microsoft.App/jobs@2023-04-01-preview"
  name      = "gh-runner"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id

  body = jsonencode({
    properties = {
      environmentId = "${azurerm_container_app_environment.aca_env.id}"
      configuration = {
        registries = [
          {
            server            = "${azurerm_container_registry.acr.login_server}"
            username          = "${azurerm_container_registry.acr.admin_username}"
            passwordSecretRef = "acrpassword"
          }
        ]
        triggerType       = "Event"
        replicaTimeout    = 1800
        replicaRetryLimit = 1
        eventTriggerConfig = {
          replicaCompletionCount = 1
          parallelism            = 1
          scale = {
            minExecutions   = 0
            maxExecutions   = 10
            pollingInterval = 30
            rules = [
              {
                type = "github-runner"
                name = "github-runner"
                metadata = {
                  githubAPIURL             = "https://api.github.com"
                  owner                     = var.gh_repo_owner
                  runnerScope               = "repo"
                  repos                     = var.gh_repo
                  targetWorkflowQueueLength = "1"
                }
                auth = [{
                  triggerParameter = "personalAccessToken"
                  secretRef        = "personal-access-token"
                }]
              }
            ]
          }
        }
        secrets = [
          {
            name  = "acrpassword"
            value = azurerm_container_registry.acr.admin_password
          },
          {
            name  = "personal-access-token"
            value = var.gh_pat
        }]
      }
      template = {
        containers = [
          {
            image = "${azurerm_container_registry.acr.login_server}/github-actions-runner:1.0"
            name  = "ghrunner"
            env = [
              {
                name      = "GITHUB_PAT"
                secretRef = "personal-access-token"
              },
              {
                name  = "REPO_URL"
                value = "https://github.com/0gis0/WebApiDotNetFramework"
              },
              {
                name  = "REGISTRATION_TOKEN_API_URL"
                value = "https://api.github.com/repos/0gis0/WebApiDotNetFramework/actions/runners/registration-token"
              }
            ]
            resources = {
              cpu    = 2.0
              memory = "4Gi"
            }
          }
        ]
      }
    }
  })
  
}


# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

resource "random_password" "password" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
}

resource "random_pet" "prefix" {
  prefix = var.prefix
  length = 1
}
