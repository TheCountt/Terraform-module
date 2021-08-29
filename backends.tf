## Introducing Backend on S3 
resource "aws_s3_bucket" "terraform_state" {
  bucket = "dapo-dev-terraform-bucket1"
  # Enable versioning so we can see the full revision history of our state files
  versioning {
    enabled = true
  }
  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# resource "aws_dynamodb_table" "terraform_locks" {
#   name         = "dapo-dev-terraform-bucket1-locks"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"
#   attribute {
#     name = "LockID"
#     type = "S"
#   }
# }

# terraform {
#   backend "s3" {
#     bucket         = "dapo-dev-terraform-bucket1"
#     key            = "global/s3/terraform.tfstate"
#     region         = "us-west-1"
#     dynamodb_table = "dapo-dev-terraform-bucket1-locks"
#     encrypt        = true
#   }
# }