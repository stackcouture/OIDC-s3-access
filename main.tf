resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_s3_bucket" "example" {
  bucket        = var.s3_bucket_name
  force_destroy = true
}

resource "aws_iam_role" "github_oidc_role" {
  name = "GitHubActionsOIDCRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      # Principal = {
      #   "Federated" : "arn:aws:iam::938320847138:oidc-provider/token.actions.githubusercontent.com"
      # },
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
#   name = "GitHubS3AccessPolicy"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "s3:ListBucket",
#           "s3:GetObject",
#           "s3:PutObject"
#         ],
#         Resource = [
#           aws_s3_bucket.example.arn,
#           "${aws_s3_bucket.example.arn}/*"
#         ]
#       }
#     ]
#   })
# }

# resource "aws_iam_policy" "s3_access_policy" {
#   name = "GitHubS3AccessPolicy"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "s3:ListBucket"
#         ],
#         Resource = [
#           "arn:aws:s3:::${var.s3_bucket_name}"
#         ]
#       },
#       {
#         Effect = "Allow",
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject"
#         ],
#         Resource = [
#           "arn:aws:s3:::${var.s3_bucket_name}/*"
#         ]
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
#   role       = aws_iam_role.github_oidc_role.name
#   policy_arn = aws_iam_policy.s3_access_policy.arn
# }

# locals {
#   s3_policy = {
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect   = "Allow",
#         Action   = ["s3:ListBucket"],
#         Resource = ["arn:aws:s3:::${var.s3_bucket_name}"]
#       },
#       {
#         Effect   = "Allow",
#         Action   = ["s3:GetObject", "s3:PutObject"],
#         Resource = ["arn:aws:s3:::${var.s3_bucket_name}/*"]
#       }
#     ]
#   }
# }

# resource "aws_iam_policy" "s3_access_policy" {
#   name   = "GitHubS3AccessPolicy"
#   policy = jsonencode(local.s3_policy)
# }


resource "aws_iam_policy" "s3_access_policy" {
  name = "GitHubS3AccessPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:ListBucket"],
        Resource = [aws_s3_bucket.example.arn]
      },
      {
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:PutObject"],
        Resource = ["${aws_s3_bucket.example.arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}