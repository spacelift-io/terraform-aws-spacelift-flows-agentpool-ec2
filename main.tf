terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Data sources
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  # AMI owner IDs by partition
  ami_owner_ids = {
    aws        = "643313122712"
    aws-us-gov = "092348861888"
  }
  image_tag_ssm_param_arn  = var.agent_image_tag_ssm_param == null ? aws_ssm_parameter.agent_image_tag[0].arn : var.agent_image_tag_ssm_param.arn
  image_tag_ssm_param_name = var.agent_image_tag_ssm_param == null ? aws_ssm_parameter.agent_image_tag[0].name : var.agent_image_tag_ssm_param.name

}

data "aws_ami" "worker" {
  most_recent = true
  name_regex  = "^spacelift-\\d{10}-x86_64$"
  owners      = [local.ami_owner_ids[data.aws_partition.current.partition]]

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Agent credentials secret
resource "aws_secretsmanager_secret" "agent_credentials" {
  name        = "flows-agent-pool-credentials"
  description = "Credentials for Flows agent pool"

  tags = {
    Purpose = "Agent pool authentication"
  }
}

resource "aws_secretsmanager_secret_version" "agent_credentials" {
  secret_id = aws_secretsmanager_secret.agent_credentials.id
  secret_string = jsonencode({
    FLOWS_AGENT_POOL_ID    = var.agent_pool_id
    FLOWS_AGENT_POOL_TOKEN = var.agent_pool_token
  })
}

# IAM instance profile
resource "aws_iam_instance_profile" "agent_instance" {
  name = "flows-agent-instance-profile"
  role = aws_iam_role.agent_instance.name
}

# Launch template for agent instances
resource "aws_launch_template" "agent_pool" {
  name_prefix = "flows-agent-"

  image_id      = data.aws_ami.worker.id
  instance_type = var.agent_instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.agent_instance.arn
  }

  network_interfaces {
    security_groups             = [aws_security_group.agent_pool.id]
    associate_public_ip_address = false
    delete_on_termination       = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type           = "gp3"
      volume_size           = 50
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.tftpl", {
    gateway_endpoint           = var.gateway_endpoint
    backend_endpoint           = var.backend_endpoint
    credentials_secret_id      = aws_secretsmanager_secret.agent_credentials.name
    region                     = data.aws_region.current.name
    ecr_repository             = var.ecr_repository_url
    private_ecr_repository     = var.ecr_repository_arn != null ? var.ecr_repository_url : ""
    image_tag_ssm_param        = local.image_tag_ssm_param_name
    flows_docker_runtime_image = var.flows_docker_runtime_image
    custom_ca_certificates     = var.custom_ca_certificates
    http_proxy                 = var.http_proxy
    datadog_api_key            = var.datadog_api_key
    datadog_site               = var.datadog_site
    datadog_environment        = var.datadog_environment
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "flows-agent"
      Type = "agent-pool"
    }
  }
}


resource "aws_ssm_parameter" "agent_image_tag" {
  count = var.agent_image_tag_ssm_param == null ? 1 : 0
  name  = "/flows/agent-pool/ImageTag"
  type  = "String"
  value = var.agent_image_tag
}

# Auto Scaling Group
resource "aws_autoscaling_group" "agent_pool" {
  name                = "flows-agent-pool"
  vpc_zone_identifier = var.reuse_vpc_id == null ? module.vpc[0].private_subnets : var.reuse_vpc_subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = null

  launch_template {
    id      = aws_launch_template.agent_pool.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 30
  default_cooldown          = 10

  termination_policies = [
    "OldestLaunchTemplate",
    "OldestInstance"
  ]

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  tag {
    key                 = "Name"
    value               = "flows-agent"
    propagate_at_launch = true
  }

  tag {
    key                 = "AgentPoolID"
    value               = "flows"
    propagate_at_launch = true
  }
}

# Lifecycle hook to allow graceful shutdown during instance termination
resource "aws_autoscaling_lifecycle_hook" "agent_termination" {
  name                   = "flows-agent-termination-hook"
  autoscaling_group_name = aws_autoscaling_group.agent_pool.name
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
  heartbeat_timeout      = 300 # 5 minutes for graceful shutdown
  default_result         = "CONTINUE"
}
