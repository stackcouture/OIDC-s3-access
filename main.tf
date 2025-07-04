resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_s3_bucket" "example" {
  bucket        = var.s3_bucket_name
  force_destroy = true
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.example.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "s3:GetObject",
        Effect    = "Allow",
        Resource  = ["${aws_s3_bucket.example.arn}/*"],
        Principal = "*"
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.example]
}

resource "aws_iam_role" "github_oidc_role" {
  name = "GitHubActionsOIDCRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub" : "repo:${var.repo_full_name}:ref:refs/heads/main"
        }
      }
    }]
  })
}

# resource "aws_iam_policy" "s3_access_policy" {
#   name   = "GitHubS3AccessPolicy"
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = ["s3:ListBucket"],
#         Resource = [aws_s3_bucket.example.arn]
#       },
#       {
#         Effect = "Allow",
#         Action = ["s3:GetObject", "s3:PutObject"],
#         Resource = ["${aws_s3_bucket.example.arn}/*"]
#       },
#        # 🛠 Add backend bucket permissions
#       {
#         Effect = "Allow",
#         Action = ["s3:ListBucket"],
#         Resource = ["arn:aws:s3:::my-tfm-state-bucket-2025"]
#       },
#       {
#         Effect = "Allow",
#         Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
#         Resource = ["arn:aws:s3:::my-tfm-state-bucket-2025/*"]
#       }
#     ]
#   })
# }


resource "aws_iam_policy" "s3_access_policy" {
  name = "GitHubS3AccessPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      # 👇 Allow access to the frontend S3 bucket
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetBucketPolicy"
        ],
        Resource = [aws_s3_bucket.example.arn]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = ["${aws_s3_bucket.example.arn}/*"]
      },

      # 👇 Allow access to the backend S3 bucket for Terraform state
      {
        Effect = "Allow",
        Action = ["s3:ListBucket", "s3:GetBucketPolicy"],
        Resource = ["arn:aws:s3:::my-tfm-state-bucket-july-2025"]
      },
      {
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
        Resource = ["arn:aws:s3:::my-tfm-state-bucket-july-2025/*"]
      },

      # 👇 Allow reading the OIDC provider (to prevent plan failure)
      {
        Effect = "Allow",
        Action = ["iam:GetOpenIDConnectProvider"],
        Resource = ["arn:aws:iam::938320847138:oidc-provider/token.actions.githubusercontent.com"]
      }
    ]
  })
}



# resource "aws_iam_policy" "s3_access_policy" {
#   name = "GitHubS3AccessPolicy"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       # ✅ Required for your frontend deployment bucket
#       {
#         Effect   = "Allow",
#         Action   = ["s3:ListBucket"],
#         Resource = [aws_s3_bucket.example.arn]
#       },
#       {
#         Effect   = "Allow",
#         Action   = ["s3:GetObject", "s3:PutObject"],
#         Resource = ["${aws_s3_bucket.example.arn}/*"]
#       },

#       # ✅ Required for your Terraform state backend bucket
#       {
#         Effect   = "Allow",
#         Action   = ["s3:ListBucket"],
#         Resource = ["arn:aws:s3:::my-tfm-state-bucket-july-2025"]
#       },
#       {
#         Effect   = "Allow",
#         Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
#         Resource = ["arn:aws:s3:::my-tfm-state-bucket-july-2025/*"]
#       }
#     ]
#   })
# }

# resource "aws_iam_policy" "s3_access_policy_main_bucket" {
#   name = "GitHubS3AccessPolicy"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       # For Terraform state bucket
#       {
#         Effect   = "Allow",
#         Action   = ["s3:ListBucket"],
#         Resource = "arn:aws:s3:::my-tfm-state-bucket-2025"
#       },
#       {
#         Effect = "Allow",
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:DeleteObject"
#         ],
#         Resource = "arn:aws:s3:::my-tfm-state-bucket-2025/*"
#       }
#     ]
#   })
# }

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}