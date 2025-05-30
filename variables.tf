variable "org_admins" {
  description = "List of GitHub usernames that should be added as admins to the organization"
  type        = set(string)
}

variable "teams" {
  description = "List of teams to create in the organization and their related resources"
  type = list(object({
    name         = string
    alias        = optional(string)
    admins       = optional(set(string), [])
    members      = optional(set(string), [])
    repos        = optional(set(string), [])
    environments = optional(map(string), {})
  }))
}

variable "tf_module_repos" {
  description = "Map of Terraform module repositories to create"
  type        = set(string)
  default     = []
}

variable "app_id" {
  description = "This is the ID of the GitHub App."
  sensitive   = true
  type        = string
}

variable "app_installation_id" {
  description = "This is the ID of the GitHub App installation."
  sensitive   = true
  type        = string
}
