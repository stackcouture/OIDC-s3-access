output "role_arn" {
  value = aws_iam_role.github_oidc_role.arn
}

output "s3_website_url" {
  description = "The URL of the S3 static website"
  value       = aws_s3_bucket_website_configuration.example.website_endpoint
}
output "bucket_name" {
  value = aws_s3_bucket.example.bucket
}