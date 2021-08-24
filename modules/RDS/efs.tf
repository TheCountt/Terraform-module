# Create EFS
resource "aws_efs_file_system" "efs" {
  tags =  {
    Name = "efs"
  }
  encrypted = true
  kms_key_id = "${var.kms_arn}"
}

# Create and add two mount volumes per AZ
resource "aws_efs_mount_target" "mounta" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.private_B[0].id
  security_groups = [aws_security_group.SG.id]
}

resource "aws_efs_mount_target" "mountb" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.private_B[1].id
  security_groups = [aws_security_group.SG.id]
}