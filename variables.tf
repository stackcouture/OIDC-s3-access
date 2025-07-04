# variable "s3_bucket_name" {
#   description = "Name of the S3 bucket"
#   type        = string
#   default     = "my-oidc-github-bucket-demo-new"
# }

# variable "repo_full_name" {
#   description = "GitHub repo in the format owner/repo"
#   type        = string
#   default     = "stackcouture/OIDC-s3-access"
# }


variable "s3_bucket_name" {
  description = "S3 bucket name"
  default     = "my-oidc-github-bucket-july-demo"
}

variable "repo_full_name" {
  description = "GitHub repo in the format org/repo"
  default     = "stackcouture/OIDC-s3-access"
}