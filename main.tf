provider "aws" {
	region = "eu-central-1"
}

data "template_file" "init" {
  template = "${file("template/init.sh.tpl")}"

vars {
    db_ip = "${aws_instance.db.private_ip}"
  }

}


resource "aws_vpc" "karl" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags {
    Name = "karl"
  } 
}

# resource "aws_internet_gateway" "karl" {
#   vpc_id = "${aws_vpc.karl.id}"
# }


resource "aws_subnet" "private_app" {
  cidr_block = "10.0.0.0/24"
  vpc_id = "${aws_vpc.karl.id}"
  map_public_ip_on_launch = true
  tags {
    Name = "app-karl"
  } 
  availability_zone = "eu-central-1b"
}



resource "aws_subnet" "public_elb" {
  cidr_block = "10.0.2.0/24"
  vpc_id = "${aws_vpc.karl.id}"
  map_public_ip_on_launch = true
  tags {
    Name = "elb-karl"
  }
  availability_zone = "eu-central-1b"
}

# 


resource "aws_subnet" "private_db" {
  cidr_block = "10.0.1.0/24"
  vpc_id = "${aws_vpc.karl.id}"

  tags {
    Name = "db-karl"
  } 
  availability_zone = "eu-central-1b"
}





resource "aws_security_group" "app" {

  name = "vpc_app"
  
  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
    # security_groups = ["${aws_security_group.db.id}"]
  }

  tags {
    Name = "karl-app"
  }

   vpc_id = "${aws_vpc.karl.id}"

}


resource "aws_security_group" "elb" {

  name = "vpc_elb"
  
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # security_groups = ["${aws_security_group.db.id}"]
  }

  tags {
    Name = "karl-elb"
  }

  vpc_id = "${aws_vpc.karl.id}"

}




resource "aws_security_group" "db" {
  name = "vpc_db"

  ingress {
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    #security_groups = ["${aws_security_group.app.id}"]
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    #security_groups = ["${aws_security_group.app.id}"]
  }
  
  tags {
    Name = "karl-db"
  }

   vpc_id = "${aws_vpc.karl.id}"

}


resource "aws_security_group" "private_db" {
  name = "vpc_private_db"


  ingress {
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   
  }

  tags {
    Name = "karl-private-db"
  }

}

resource "aws_security_group" "private_app" {
  name = "vpc_private_app"

  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
 
   cidr_blocks = ["0.0.0.0/0"]
  }



  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags {
    Name = "karl-private-app"
  }

}


resource "aws_security_group" "public_elb" {
  name = "vpc_public_elb"

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
 
   cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags {
    Name = "elb-public-karl"
  }

}


resource "aws_internet_gateway" "public_elb" {
    vpc_id = "${aws_vpc.karl.id}"
     tags {
    Name = "ig-karl"
  }
}


resource "aws_route_table" "public_elb" {
    vpc_id = "${aws_vpc.karl.id}"

    route {
       cidr_block = "0.0.0.0/0"
       gateway_id = "${aws_internet_gateway.public_elb.id}"
     
    }


    tags {
        Name = "Public Subnet Route"
    }
}



# resource "aws_route_table" "private" {
#     vpc_id = "${aws_vpc.karl.id}"

#     route {
#       cidr_block="10.0.0.0/"
#     }


#     tags {
#         Name = "Private Subnet"
#     }
# }



resource "aws_route_table_association" "public" {
    subnet_id = "${aws_subnet.public_elb.id}"
    route_table_id = "${aws_route_table.public_elb.id}"
}


# resource "aws_route_table_association" "private" {
#     subnet_id = "${aws_subnet.private.id}"
#     route_table_id = "${aws_route_table.private.id}"
# }



resource "aws_network_acl" "private_app" {
  vpc_id = "${aws_vpc.karl.id}"

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.0.2.0/24"
    from_port  = 0
    to_port    = 65535
  }

   egress {
    protocol   = "tcp"
    rule_no    = 199
    action     = "allow"
    cidr_block = "10.0.1.0/24"
    from_port  = 0
    to_port    = 65535
  }



  ingress {
    protocol   =  "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.0.2.0/24"
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   =  "tcp"
    rule_no    = 199
    action     = "allow"
    cidr_block = "10.0.1.0/24"
    from_port  = 0
    to_port    = 65535
  }
 subnet_ids =["${aws_subnet.private_app.id}"]

  tags {
    Name = "private-app-karl"
  }
}

resource "aws_network_acl" "public_elb" {
  vpc_id = "${aws_vpc.karl.id}"

  egress {
    protocol   =  -1
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }



  ingress {
    protocol   =  -1
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
 subnet_ids =["${aws_subnet.public_elb.id}"]

  tags {
    Name = "public-elb-karl"
  }
}




resource "aws_network_acl" "private_db" {
  vpc_id = "${aws_vpc.karl.id}"


 ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "10.0.0.0/24"
    from_port  = 27017
    to_port    = 27017
  }
  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "10.0.0.0/24"
    from_port  = 0
    to_port    = 65535
  }
  subnet_ids =["${aws_subnet.private_db.id}"]



  tags {
    Name = "private-app-karl"
  }
}


# resource "aws_instance" "app" {
#   ami           = "ami-2d098e42"

#   instance_type = "t2.micro" 
#   tags {
#    Name           = "app-karl"

#   }
#   subnet_id= "${aws_subnet.private_app.id}"

#   lifecycle{
#     create_before_destroy=true
#   }

#   vpc_security_group_ids = ["${aws_security_group.app.id}"]
#   user_data="${data.template_file.init.rendered}"


# }


resource "aws_instance" "db" {
  ami = "ami-9f23a4f0"
  instance_type = "t2.micro"
  tags {
    Name = "db-karl"
  }
  subnet_id= "${aws_subnet.private_db.id}"

  #vpc_security_group_ids = ["${aws_security_group.db.id}"]

   lifecycle{
    create_before_destroy=true
  }

  vpc_security_group_ids = ["${aws_security_group.db.id}"]

}

output "ip_db" {
  value = "${aws_instance.db.private_ip}"
}





resource "aws_default_network_acl" "default" {
  default_network_acl_id = "${aws_vpc.karl.default_network_acl_id}"

 ingress {
    protocol   = -1
    rule_no    = 100
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

 egress {
    protocol   = -1
    rule_no    = 100
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}




resource "aws_elb" "karl" {
  name               = "karl-elb"

  subnets= ["${aws_subnet.public_elb.id}"]
  security_groups = ["${aws_security_group.elb.id}"]


  # access_logs {
  #   bucket        = "foo"
  #   bucket_prefix = "bar"
  #   interval      = 60
  # }

  listener {
    instance_port     = 3000
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }



  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:3000/"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400




  tags {
    Name = "elb-karl"
  }
}


# resource "aws_lb" "elb" {
#   name            = "karl-elb"
#   internal        = false
#   security_groups = ["${aws_security_group.elb.id}"]

#   subnet_id = "${aws_subnet.elb.id}"

#   enable_deletion_protection = true


#   vpc_security_group_ids = ["${aws_security_group.app.id}"]



#   tags {
#     Environment = "production"
#   }
# }



# resource "aws_security_group" "elb" 


# resource "aws_elb_attachment" "karl" {
#   elb      = "${aws_elb.karl.id}"
#   instance = "${aws_instance.app.id}"
# }

#################################################################



resource "aws_launch_configuration" "karl_cluster" {
  image_id= "ami-dffc7ab0"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.app.id}"]
  user_data = "${data.template_file.init.rendered}"

  lifecycle {
    create_before_destroy = true
  }



}





resource "aws_autoscaling_group" "karl_scalegroup" {
  launch_configuration = "${aws_launch_configuration.karl_cluster.name}"
 
  min_size = 1
  max_size = 4
  enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
  metrics_granularity="1Minute"
  load_balancers= ["${aws_elb.karl.id}"]
  health_check_type="ELB"
  force_delete = true
 

  tags {
    key = "Name"
    value = "karl-app"
    propagate_at_launch = true
  }

  vpc_zone_identifier=["${aws_subnet.private_app.id}"]
}


# resource “aws_autoscaling_group” “scalegroup” {
# launch_configuration = “${aws_launch_configuration.webcluster.name}”
# availability_zones = [“${data.aws_availability_zones.allzones.names}”]
# min_size = 1
# max_size = 4
# enabled_metrics = [“GroupMinSize”, “GroupMaxSize”, “GroupDesiredCapacity”, “GroupInServiceInstances”, “GroupTotalInstances”]
# metrics_granularity=”1Minute”
# load_balancers= [“${aws_elb.elb1.id}”]
# health_check_type=”ELB”
# tag {
# key = “Name”
# value = “terraform-asg-example”
# propagate_at_launch = true
# }
# }

resource "aws_autoscaling_policy" "autopolicy" {
name = "karl-policy"
scaling_adjustment = 1
adjustment_type = "ChangeInCapacity"
cooldown = 300
autoscaling_group_name = "${aws_autoscaling_group.karl_scalegroup.name}"
}


resource "aws_cloudwatch_metric_alarm" "cpualarm" {
  alarm_name = "terraform-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "5"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.karl_scalegroup.name}"
  }

  alarm_description = "This metric monitor EC2 instance cpu utilization"
  alarm_actions = ["${aws_autoscaling_policy.autopolicy.arn}"]
}



resource "aws_autoscaling_policy" "autopolicy-down" {
  name = "terraform-autoplicy-down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.karl_scalegroup.name}"
}


resource "aws_cloudwatch_metric_alarm" "cpualarm-down" {
  alarm_name = "terraform-alarm-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.karl_scalegroup.name}"
  }

  alarm_description = "This metric monitor EC2 instance cpu utilization"
  alarm_actions = ["${aws_autoscaling_policy.autopolicy-down.arn}"]
}


resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = "${aws_autoscaling_group.karl_scalegroup.id}"
  elb                    = "${aws_elb.karl.id}"
}


output "elb-dns" {
value = "${aws_elb.karl.dns_name}"
}














