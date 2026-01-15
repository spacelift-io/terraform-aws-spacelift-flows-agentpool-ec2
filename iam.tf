# IAM role for agent instances
resource "aws_iam_role" "agent_instance" {
  name = "flows-agent-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM policy for agent instances
resource "aws_iam_role_policy" "agent_instance" {
  name = "flows-agent-instance-policy"
  role = aws_iam_role.agent_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue"
          ]
          Resource = aws_secretsmanager_secret.agent_credentials.arn
        },
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "autoscaling:DescribeAutoScalingInstances"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "autoscaling:CompleteLifecycleAction"
          ]
          Resource = aws_autoscaling_group.agent_pool.arn
        },
        {
          Effect = "Allow"
          Action = [
            "cloudwatch:PutMetricData"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "ecr-public:GetAuthorizationToken",
            "sts:GetServiceBearerToken"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "ecr-public:BatchCheckLayerAvailability",
            "ecr-public:GetDownloadUrlForLayer",
            "ecr-public:BatchGetImage"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "ec2:DescribeInstances",
            "ec2:DescribeTags"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "ssm:GetParameter"
          ]
          Resource = local.image_tag_ssm_param_arn
        },
      ],
      var.ecr_repository_arn != null ? [
        {
          Effect = "Allow"
          Action = [
            "ecr:GetAuthorizationToken"
          ]
          Resource = "*"
        },
      ] : [],
      var.ecr_repository_arn != null ? [
        {
          Effect = "Allow"
          Action = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage"
          ]
          Resource = [
            var.ecr_repository_arn,
            "${var.ecr_repository_arn}/*"
          ]
        }
      ] : []
    )
  })
}

locals {
  iam_managed_policies = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AutoScalingReadOnlyAccess",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(local.iam_managed_policies)

  role       = aws_iam_role.agent_instance.name
  policy_arn = each.value
}
