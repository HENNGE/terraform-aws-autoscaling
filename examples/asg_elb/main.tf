provider "aws" {
  region = "eu-west-1"
}

##############################################################
# Data sources to get VPC, subnets and security group details
##############################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  name   = "default"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

######
# Launch template and autoscaling group
######
module "example_asg" {
  source = "../../"

  name = "example-with-elb"

  # Launch template
  #
  # launch_template = "my-existing-launch-template" # Use the existing launch template
  # create_lt = false # disables creation of launch template
  lt_name = "example-lt"

  image_id = data.aws_ami.amazon_linux.id
  instance_types = [
    { instance_type = "t2.micro" },
    { instance_type = "t3.micro" }
  ]
  security_groups = [data.aws_security_group.default.id]
  load_balancers  = [module.elb.this_elb_id]

  block_device_mappings = [
    {
      # Root block device
      device_name = "/dev/xvda"

      ebs = [
        {
          volume_type = "gp2"
          volume_size = 50
        },
      ]
    },
    {
      # EBS Block Device
      device_name = "/dev/xvdz"

      ebs = [
        {
          volume_type = "gp2"
          volume_size = 50
        },
      ]
    },
  ]

  # Auto scaling group
  asg_name                  = "example-asg"
  vpc_zone_identifier       = data.aws_subnet_ids.all.ids
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 0
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = "dev"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "megasecret"
      propagate_at_launch = true
    },
  ]
}

######
# ELB
######
module "elb" {
  source  = "terraform-aws-modules/elb/aws"
  version = "~> 2.0"

  name = "elb-example"

  subnets         = data.aws_subnet_ids.all.ids
  security_groups = [data.aws_security_group.default.id]
  internal        = false

  listener = [
    {
      instance_port     = "80"
      instance_protocol = "HTTP"
      lb_port           = "80"
      lb_protocol       = "HTTP"
    },
  ]

  health_check = {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}
