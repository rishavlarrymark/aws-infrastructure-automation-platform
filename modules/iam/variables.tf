
variable "role_name" {
  description = "IAM role name"
  type        = string
}

variable "service_principal" {
  description = "AWS service that can assume this role"
  type        = string
}

variable "policy_actions" {
  description = "Allowed IAM actions (least privilege)"
  type        = list(string)

  validation {
    condition     = length(var.policy_actions) > 0
    error_message = "At least one IAM action is required."
  }
}

variable "policy_resources" {
  description = "Resources the policy applies to"
  type        = list(string)
}

variable "tags" {
  description = "Mandatory cost and ownership tags"
  type        = map(string)
}
