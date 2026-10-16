# Terraform AWS Spacelift Flows Agent Pool (EC2)

Terraform module for running a Spacelift Flows agent pool on AWS EC2 instances.

## What this does

This module sets up an auto-scaling group of EC2 instances that run Flows agents. The agents connect to the Flows backend and execute workflow tasks. It handles the networking, IAM permissions, secrets management, and instance lifecycle.

The module can either create a new VPC or use an existing one. Instances run in private subnets with NAT gateway access for pulling container images and connecting to Flows endpoints.

## Usage

```hcl
module "flows_agent_pool" {
  source = "github.com/spacelift-io/terraform-aws-spacelift-flows-agentpool-ec2?ref=main"

  agent_pool_id    = "your-agent-pool-id"
  agent_pool_token = "your-agent-pool-token"
  backend_endpoint = "https://useflows.eu"
  gateway_endpoint = "https://gateway.useflows.eu"

  agent_instance_type = "c7i.xlarge"
  min_size            = 1
  max_size            = 10
}
```

### Instance type

The default is `c7i.xlarge`. Avoid burstable instance families (`t2`, `t3`,
`t4g`): agents frequently start up new Node.js runtimes, which can exhaust the
CPU credit balance and throttle the instance. Pick a general-purpose or
compute-optimized instance instead.

### Runtime sandboxing with gVisor

Each runtime container runs under [gVisor](https://gvisor.dev/) (`runsc`),
which intercepts system calls in user space instead of passing them to the
host kernel. This provides safe sandboxing for app code and flow evaluations.

### Using an existing VPC

```hcl
module "flows_agent_pool" {
  source = "github.com/spacelift-io/terraform-aws-spacelift-flows-agentpool-ec2?ref=main"

  agent_pool_id    = "your-agent-pool-id"
  agent_pool_token = "your-agent-pool-token"
  backend_endpoint = "https://useflows.eu"
  gateway_endpoint = "https://gateway.useflows.eu"

  reuse_vpc_id         = "vpc-12345678"
  reuse_vpc_subnet_ids = ["subnet-abc", "subnet-def", "subnet-ghi"]
}
```

### Using an existing credentials secret

By default the module stores `agent_pool_id` and `agent_pool_token` in a new
Secrets Manager secret named `<name>-agent-pool-credentials`. If you already keep
the credentials in Secrets Manager, pass its ARN instead. The module then skips
creating its own secret and the token never passes through Terraform. The
secret must be a JSON object with `FLOWS_AGENT_POOL_ID` and
`FLOWS_AGENT_POOL_TOKEN` keys.

```hcl
module "flows_agent_pool" {
  source = "github.com/spacelift-io/terraform-aws-spacelift-flows-agentpool-ec2?ref=main"

  existing_credentials_secret_arn = "arn:aws:secretsmanager:eu-central-1:123456789012:secret:prod/flows-worker-AbCdEf"
  backend_endpoint                = "https://useflows.eu"
  gateway_endpoint                = "https://gateway.useflows.eu"
}
```

If the secret is encrypted with a customer-managed KMS key, also set
`credentials_secret_kms_key_arn` so the instances can decrypt it.

## Requirements

- Terraform >= 1.2
- AWS provider ~> 6.0

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| agent_pool_id | ID of the agent pool. Required unless `existing_credentials_secret_arn` is set | `string` | `null` | no |
| agent_pool_token | Token for the agent pool. Required unless `existing_credentials_secret_arn` is set | `string` | `null` | no |
| existing_credentials_secret_arn | ARN of an existing Secrets Manager secret with `FLOWS_AGENT_POOL_ID` and `FLOWS_AGENT_POOL_TOKEN` keys. If set, the module does not create its own secret | `string` | `null` | no |
| credentials_secret_kms_key_arn | ARN of the customer-managed KMS key encrypting the existing credentials secret | `string` | `null` | no |
| backend_endpoint | Backend endpoint URL for agents to connect | `string` | n/a | yes |
| gateway_endpoint | Gateway endpoint URL for agents to connect | `string` | n/a | yes |
| agent_instance_type | EC2 instance type for agents | `string` | `"c7i.xlarge"` | no |
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
- Secrets Manager secret for agent credentials (optional, if not providing an existing secret)
- Security group allowing outbound traffic
- VPC with public/private subnets and NAT gateway (optional, if not reusing existing VPC)
- SSM parameter for agent image tag (optional, if not providing existing parameter)
