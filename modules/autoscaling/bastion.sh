<<EOF
#! /bin/bash
yum -y install httpd
echo "Hello, from Terraform" > /var/www/html/index.html
systemctl start httpd
systemctl enable httpd
EOF