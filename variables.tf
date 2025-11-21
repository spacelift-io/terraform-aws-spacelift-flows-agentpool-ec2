# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "backend_endpoint" {
  description = "Backend endpoint URL for agents to connect"
  type        = string
}

variable "gateway_endpoint" {
  description = "Gateway endpoint URL for agents to connect"
  type        = string
}

variable "agent_instance_type" {
  description = "EC2 instance type for agents"
  type        = string
  default     = "c7i.xlarge"
}

variable "min_size" {
  description = "Minimum number of agent instances"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of agent instances"
  type        = number
  default     = 10
}

variable "desired_capacity" {
  description = "Desired number of agent instances"
  type        = number
  default     = 2
}

variable "ecr_repository_url" {
  description = "ECR repository URL for Flows images"
  type        = string
  default = "public.ecr.aws/w5z2f6e8/spacelift-flows-agent"
}

variable "ecr_repository_arn" {
  description = "ECR repository ARN for Flows images (optional, for private ECR)"
  type        = string
  default     = null
}

variable "agent_pool_id" {
  description = "ID of the agent pool"
  type        = string
}

variable "agent_pool_token" {
  description = "Token for the agent pool"
  type        = string
  sensitive   = true
}

variable "reuse_vpc_id" {
  description = "Optionally provide an existing vpc id to reuse"
  default     = null
}

variable "reuse_vpc_subnet_ids" {
  description = "Provide existing subnet ids to reuse, if reusing VPC."
  type        = list(string)
  default     = null
}

variable "agent_image_tag" {
  type    = string
  default = "latest"
}

variable "agent_image_tag_ssm_param" {
  description = "SSM parameter for agent image tag. If provided, will use this instead of creating a new one."
  type = object({
    arn  = string
    name = string
  })
  default = null
}
