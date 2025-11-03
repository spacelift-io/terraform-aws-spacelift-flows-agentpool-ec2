# Terraform AWS Spacelift Flows Agent Pool (EC2)

Terraform module for running a Spacelift Flows agent pool on AWS EC2 instances.

## What this does

This module sets up an auto-scaling group of EC2 instances that run Flows agents. The agents connect to your Flows backend and execute workflow tasks. It handles the networking, IAM permissions, secrets management, and instance lifecycle.

The module can either create a new VPC or use an existing one. Instances run in private subnets with NAT gateway access for pulling container images and connecting to Flows endpoints.

## Usage

```hcl
module "flows_agent_pool" {
  source = "github.com/spacelift-io/terraform-aws-spacelift-flows-agentpool-ec2?ref=main"

  agent_pool_id    = "your-agent-pool-id"
  agent_pool_token = "your-agent-pool-token"
  backend_endpoint = "https://flows.example.com"
  gateway_endpoint = "https://gateway.flows.example.com"

  agent_instance_type = "t3.medium"
  min_size            = 1
  max_size            = 10
}
```

### Using an existing VPC

```hcl
module "flows_agent_pool" {
  source = "github.com/spacelift-io/terraform-aws-spacelift-flows-agentpool-ec2?ref=main"

  agent_pool_id    = "your-agent-pool-id"
  agent_pool_token = "your-agent-pool-token"
  backend_endpoint = "https://flows.example.com"
  gateway_endpoint = "https://gateway.flows.example.com"

  reuse_vpc_id         = "vpc-12345678"
  reuse_vpc_subnet_ids = ["subnet-abc", "subnet-def", "subnet-ghi"]
}
```

### Private ECR repository

If you're mirroring the Flows agent image to a private ECR repository:

```hcl
module "flows_agent_pool" {
  source = "spacelift-io/spacelift-flows-agentpool-ec2/aws"

  agent_pool_id    = "your-agent-pool-id"
  agent_pool_token = "your-agent-pool-token"
  backend_endpoint = "https://flows.example.com"
  gateway_endpoint = "https://gateway.flows.example.com"

  ecr_repository_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/flows-agent"
  ecr_repository_arn = "arn:aws:ecr:us-east-1:123456789012:repository/flows-agent"
}
```

## Requirements

- Terraform >= 1.0
- AWS provider ~> 6.0

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| agent_pool_id | ID of the agent pool | `string` | n/a | yes |
| agent_pool_token | Token for the agent pool | `string` | n/a | yes |
| backend_endpoint | Backend endpoint URL for agents to connect | `string` | n/a | yes |
| gateway_endpoint | Gateway endpoint URL for agents to connect | `string` | n/a | yes |
| agent_instance_type | EC2 instance type for agents | `string` | `"t3.medium"` | no |
| min_size | Minimum number of agent instances | `number` | `1` | no |
| max_size | Maximum number of agent instances | `number` | `10` | no |
| ecr_repository_url | ECR repository URL for Flows images | `string` | `"public.ecr.aws/w5z2f6e8/spacelift-flows-agent"` | no |
| ecr_repository_arn | ECR repository ARN for Flows images (optional, for private ECR) | `string` | `null` | no |
| reuse_vpc_id | Optionally provide an existing VPC ID to reuse | `string` | `null` | no |
| reuse_vpc_subnet_ids | Provide existing subnet IDs to reuse, if reusing VPC | `list(string)` | `null` | no |
| agent_image_tag | Docker image tag for the agent | `string` | `"latest"` | no |
| agent_image_tag_ssm_param | SSM parameter for agent image tag. If provided, will use this instead of creating a new one | `object({ arn = string, name = string })` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| autoscaling_group_name | Name of the agent pool autoscaling group |
| autoscaling_group_arn | ARN of the agent pool autoscaling group |

## What gets created

- Auto Scaling Group with EC2 instances running the Flows agent
- Launch template with the Spacelift AMI
- IAM role and instance profile for agent permissions
- Secrets Manager secret for agent credentials
- Security group allowing outbound traffic
- VPC with public/private subnets and NAT gateway (optional, if not reusing existing VPC)
- SSM parameter for agent image tag (optional, if not providing existing parameter)
