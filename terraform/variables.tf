variable "subscription_id" {
  description = "Azure subscription ID used by the AzureRM provider."
  type        = string
  default     = "8d329d72-8494-4e54-843a-78f0e2544c3a"
}

variable "azure_location" {
  description = "Azure region where all resources will be deployed."
  type        = string
  default     = "eastus"
}
