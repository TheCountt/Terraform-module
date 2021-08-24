# create IAM role for all instance
resource "aws_iam_role" "my-role" {
  name = "my-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "%your_name%-role"
  }
}

# create IAM policy for all instance
resource "aws_iam_policy" "my-policy" {
  name        = "my_policy"
  path        = "/"
  description = "%Your name% policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# attach IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "my-attach" {
  role       = aws_iam_role.my-role.name
  policy_arn = aws_iam_policy.my-policy.arn
}

# create instance profile and attach to the IAM role
resource "aws_iam_instance_profile" "my-profile" {
  name = "aws_instance_profile_my-profile"
  role = aws_iam_role.my-role.name
}

# provide a public key for the instance
resource "aws_key_pair" "devops-key" {
  key_name   = "devops-key"
  public_key = var.public_key_path
}
# public_key_path                = "ssh-rsa %your_key%"