# Variables
variable "name" {
  description = "Name prefix used for all resources. Must be unique per deployment in the same AWS account/region."
  type        = string
  default     = "flows"
}

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
  description = "Number of agent instances the pool starts with"
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

variable "create_credentials_secret" {
  description = "Whether to create a Secrets Manager secret from agent_pool_id and agent_pool_token. Set to false and provide existing_credentials_secret_arn to use an existing secret instead."
  type        = bool
  default     = true
}

variable "agent_pool_id" {
  description = "ID of the agent pool. Required when create_credentials_secret is true."
  type        = string
  default     = null
}

variable "agent_pool_token" {
  description = "Token for the agent pool. Required when create_credentials_secret is true."
  type        = string
  default     = null
  sensitive   = true
}

variable "existing_credentials_secret_arn" {
  description = "ARN of an existing Secrets Manager secret holding the agent pool credentials as JSON with FLOWS_AGENT_POOL_ID and FLOWS_AGENT_POOL_TOKEN keys. Required when create_credentials_secret is false."
  type        = string
  default     = null
}

variable "credentials_secret_kms_key_arn" {
  description = "ARN of the customer-managed KMS key encrypting the existing credentials secret. Only needed when existing_credentials_secret_arn uses a CMK."
  type        = string
  default     = null
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

variable "associate_public_ip_address" {
  description = "Whether agent instances get a public IP address. false (default) expects private subnets with egress through a NAT gateway or proxy. true expects public subnets with a route to an Internet Gateway; when the module creates the VPC, agents are placed in its public subnets and no NAT gateway is created. null defers to the subnet's map_public_ip_on_launch setting."
  type        = bool
  default     = false
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

variable "flows_docker_runtime_image" {
  description = "Docker runtime image for Flows executor"
  type        = string
  default     = null
}

variable "custom_ca_certificates" {
  description = "Custom CA certificates to inject into docker containers"
  type        = string
  default     = null
}

variable "http_proxy" {
  description = "HTTP proxy URL for docker containers"
  type        = string
  default     = null
}

variable "cloudwatch_log_retention_days" {
  description = "Retention period in days for CloudWatch log group /aws/ec2/flows-agent"
  type        = number
  default     = 7
}

variable "custom_userdata_inject" {
  description = "Custom bash script to inject into user_data before starting the Flows agent. Useful for setting up monitoring agents (e.g., Datadog), additional dependencies, or custom configuration."
  type        = string
  default     = null
}