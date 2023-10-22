variable "prefix" {
  description = "The prefix which should be used for all resources "
  default = "phongmx"
}

variable "environment"{
  description = "The environment should be used for all resources "
  default = "testing"
}

variable "location" {
  description = "The Azure Region in which all resources should be created."
  default = "East US" 
}

variable "username"{
  default = "phongmx"
}

variable "password"{
  default= "Password11"
}

variable "server_names"{
  type = list
  default = ["uat","int"]
}

variable "packerImageId"{
  default = "/subscriptions/63e57a67-37de-4afd-82b5-03b188e46c5d/resourceGroups/Azuredevops/providers/Microsoft.Compute/images/phongmxpacker"
}

variable "vm_count"{
  default = "2"
}