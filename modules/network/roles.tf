# create IAM role for all instance
resource "aws_iam_role" "terraform-role" {
  name = "terraform-role"
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
    tag-key = "terraform-role"
  }
}

# create IAM policy for all instance
resource "aws_iam_policy" "terraform-policy" {
  name        = "terraform_policy"
  path        = "/"
  description = "terraform policy"
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
resource "aws_iam_role_policy_attachment" "terraform-attach" {
  role       = aws_iam_role.terraform-role.name
  policy_arn = aws_iam_policy.terraform-policy.arn
}

# create instance profile and attach to the IAM role
resource "aws_iam_instance_profile" "terraform-profile" {
  name = "aws_instance_profile_terraform-profile"
  role = aws_iam_role.terraform-role.name
}

# provide a public key for the instance
resource "aws_key_pair" "terraform-key" {
  key_name   = "terraform-key"
  public_key = file("C:/Users/user/.ssh/id_rsa.pub")
}
# public_key_path                = "ssh-rsa %your_key%"