resource "aws_key_pair" "user" {
  key_name   = "user"
  public_key = file("C:/Users/user/.ssh/id_rsa.pub")
}