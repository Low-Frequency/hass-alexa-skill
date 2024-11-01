variable "name" {
  description = "Name of the IAM role"
  type        = string
}

variable "description" {
  description = "Description of the created IAM role"
  type        = string
}

variable "policy_document" {
  description = "The policy document to use"
  type        = object({
    effect  = string
    actions = set(string)
    principals = object({
      type        = string
      identifiers = set(string)
    })
  })
}

variable "policy" {
  description = "The IAM policy to be created"
  type        = object({
    action   = set(string)
    effect   = string
    resource = string
  })
}
