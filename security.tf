# creating dynamic ingress security groups
locals {
  security_groups = {
    ALB = {
      name        = "ALB-sg"
      description = "for external loadbalncer"
      ingress = {
        HTTPS = {
          from     = 0
          to       = 0
          protocol = "-1"
        }
      }


    }

    # security group for bastion
    bastion = {
      name        = "bastion-sg"
      description = "for bastion instances"
      ingress = {
        ssh = {
          from     = 22
          to       = 22
          protocol = "tcp"
        }
      }
    }

    # security group for nginx
    nginx = {
      name        = "nginx-sg"
      description = "nginx instances"
      ingress = {
        HTTP = {
          from     = 80
          to       = 80
          protocol = "tcp"
        }
      }

      ingress = {
        ssh = {
          from     = 22
          to       = 22
          protocol = "tcp"
        }
      }
    }

    # security group for IALB
    IALB = {
      name        = "IALB-sg"
      description = "IALB security group"
      ingress = {
        HTTP = {
          from     = 80
          to       = 80
          protocol = "tcp"
        }
      }
    }


    # security group for webservers
    webservers = {
      name        = "webservers-sg"
      description = "webservers security group"
      ingress = {
        HTTP = {
          from     = 80
          to       = 80
          protocol = "tcp"
        }
      }
      ingress = {
        ssh = {
          from     = 22
          to       = 22
          protocol = "tcp"
        }
      }
    }


    # security group for data-layer
    data-layer = {
      name        = "DL-sg"
      description = "data layer security group"
      ingress = {
        nfs = {
          from     = 2049
          to       = 2049
          protocol = "tcp"
        }
      }

      ingress = {
        mysql = {
          from     = 3306
          to       = 3306
          protocol = "tcp"
        }
      }
      ingress = {
        ssh = {
          from     = 22
          to       = 22
          protocol = "tcp"
        }
      }
    }
  }
}