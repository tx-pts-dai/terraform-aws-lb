# terraform-aws-lb module

Module for handling application load balancers, listeners, target groups and route53 records creation. It also handles SSL certificates validation through DNS. Besides the default target group, multiple target groups can be reached through path based routing from the same load balancer. The name of the target group is used as the path. For example, if the target group name is `api` then it will be reachable at `hostname/api/*`, then . By default, all http traffic is redirected to https. The load balancer is also protected via Okta as optional.

Security groups are handled internally and only allow http and https traffic in.

## Usage

```hcl
module "lb" {
  source               = "github.com/tx-pts-dai/terraform-aws-lb"
  app_url              = "my-subdomain.domain"
  name                 = "my-deployment"
  vpc_id               = local.vpc_id
  subnets              = local.public_subnet.ids
  zone_id              = data.aws_route53_zone.my_zone.zone_id
  default_target_group = {
    name = "client"
    protocol = "HTTP"
    port = 80
    health_check = {
      path = "/health"
      port = "traffic-port"
      protocol = "HTTP"
      matcher = "200"
    }
    tags = {
      Name = "Client"
    }
  }
}
```

As optional, extra target groups can be set. Those could be then reached through path based routing. Each target group must specify the following properties. As optional, they can have dedicated tags and health checks properties.

```hcl
module "lb" {
  source               = "github.com/tx-pts-dai/terraform-aws-lb"
  ...
  path_target_groups   = [
    {
      name = "ws"
      protocol = "HTTP"
      port = 3000
      health_check = {
        path = "/health"
        port = "traffic-port"
        protocol = "HTTP"
        matcher = "200"
      }
      tags = {
        Name = "Web Service"
      }
    },
    {
      name = "api"
      protocol = "HTTP"
      port = 3000
      health_check = {
        path = "/health"
        port = "traffic-port"
        protocol = "HTTP"
        matcher = "200"
      }
      tags = {
        Name = "API"
      }
    }
  ]
}
```

For other optional inputs, see Inputs section

## Enabling logging

ALB logs can be enabled by setting the following input:

```hcl
  "log_bucket" = "arn-of-an-existing-bucket"
```

When empty, there are no logs saved.

## Enabling OKTA

OKTA can be enabled with the following inputs:

```hcl
  okta = {
    enabled         = true
    aws_secret_name = "aws-secret-name"
    scopes          = ["openid", "groups"]
  }
```

The secret is a JSON key-value pair that must contain the following keys:

- okta_client_id
- okta_client_secret
- okta_login_url

and the `scopes` is optional and defaults to `["openid"]`

## DNS

The A and CNAME DNS records for the loadbalancer and the AWS certificate validation will automatically be created by giving the AWS Route53 ZoneID were to create them:

```hcl
  zone_id = "AWS_ROUTER53_ZONEID"
```

If the worlflow doesn't have permissions to the AWS Route53 Zone OR if the zone is not managed by Route53 (Cloudflare for example), then the *zone_id* parameter should be "" and the following records need to be created manually:

- CNAME to the loadbalancer (to have a "nice" name for the service)
- CNAME for the AWS Certificate validation

## Contributing

< issues and contribution guidelines for public modules >

### Pre-Commit

Installation: [install pre-commit](https://pre-commit.com/) and execute `pre-commit install`. This will generate pre-commit hooks according to the config in `.pre-commit-config.yaml`

Before submitting a PR be sure to have used the pre-commit hooks or run: `pre-commit run -a`

The `pre-commit` command will run:

- Terraform fmt
- Terraform validate
- Terraform docs
- Terraform validate with tflint
- check for merge conflicts
- fix end of files

as described in the `.pre-commit-config.yaml` file

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_lb.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_rule.https_listener_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.path](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_route53_record.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.app_ssl_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_secretsmanager_secret.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret_version.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_url"></a> [app\_url](#input\_app\_url) | the domain name of the Application | `string` | n/a | yes |
| <a name="input_create_certificate_validation_dns_record"></a> [create\_certificate\_validation\_dns\_record](#input\_create\_certificate\_validation\_dns\_record) | Whether to create the DNS record to validate the custom certificate being created by the module. | `bool` | `true` | no |
| <a name="input_create_lb_dns_record"></a> [create\_lb\_dns\_record](#input\_create\_lb\_dns\_record) | Whether to create the DNS record pointing from 'app\_url' to the LB-created DNS name. 'var.zone\_id' must be set. | `bool` | `false` | no |
| <a name="input_default_target_group"></a> [default\_target\_group](#input\_default\_target\_group) | Definition of the default target group. The one reachable by default ('/'). | <pre>object({<br>    name     = string<br>    protocol = optional(string, "HTTP")<br>    port     = number<br>    health_check = object({<br>      path     = string<br>      port     = optional(string, "traffic-port")<br>      protocol = optional(string, "HTTP")<br>      matcher  = optional(string, "200")<br>    })<br>    tags = map(string)<br>  })</pre> | n/a | yes |
| <a name="input_lb_idle_timeout_in_seconds"></a> [lb\_idle\_timeout\_in\_seconds](#input\_lb\_idle\_timeout\_in\_seconds) | the connection idle timeout of the application load balancer (between 1 and 4000) | `number` | `60` | no |
| <a name="input_log_bucket"></a> [log\_bucket](#input\_log\_bucket) | the existing S3 Bucket name where to store the logs - if the bucket name is empty logging is disabled | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | The name for the load balancer. | `string` | n/a | yes |
| <a name="input_okta"></a> [okta](#input\_okta) | Integrate Okta directly at the ALB level. 'aws\_secret\_name' is the name of the secret where 'okta\_client\_id', 'okta\_client\_secret' and 'okta\_login\_url' are set. | <pre>object({<br>    enabled         = optional(bool, false)<br>    aws_secret_name = optional(string, "")<br>    scopes          = optional(list(string), ["openid"])<br>  })</pre> | `{}` | no |
| <a name="input_path_target_groups"></a> [path\_target\_groups](#input\_path\_target\_groups) | Definition of the target groups. Each target group is accessed via path based routing. | <pre>list(object({<br>    name     = string<br>    protocol = optional(string, "HTTP")<br>    paths    = list(string)<br>    port     = number<br>    health_check = object({<br>      path     = string<br>      port     = optional(string, "traffic-port")<br>      protocol = optional(string, "HTTP")<br>      matcher  = optional(string, "200")<br>    })<br>    tags = map(string)<br>  }))</pre> | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | A list of public subnet IDs for the load balancer. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to the load balancer and associated resources. | `map(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC in which to create the load balancer. | `string` | n/a | yes |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | If set, the Route 53 zone id into which the DNS records will be created. 'var.zone\_id' must be set. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_default_target_group_arn"></a> [default\_target\_group\_arn](#output\_default\_target\_group\_arn) | Default TG arn |
| <a name="output_default_target_group_arn_suffix"></a> [default\_target\_group\_arn\_suffix](#output\_default\_target\_group\_arn\_suffix) | Default TG arn suffix |
| <a name="output_load_balancer_arn"></a> [load\_balancer\_arn](#output\_load\_balancer\_arn) | The ARN of the load balancer. |
| <a name="output_load_balancer_arn_suffix"></a> [load\_balancer\_arn\_suffix](#output\_load\_balancer\_arn\_suffix) | The ARN suffix of the load balancer. |
| <a name="output_load_balancer_dns_name"></a> [load\_balancer\_dns\_name](#output\_load\_balancer\_dns\_name) | The DNS of the load balancer. |
| <a name="output_path_target_groups_arn"></a> [path\_target\_groups\_arn](#output\_path\_target\_groups\_arn) | Path base routed TG arn |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | The security group ID linked to the load balancer |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is maintained by [Alfredo Gottardo](https://github.com/AlfGot), [David Beauvererd](https://github.com/Davidoutz), [Davide Cammarata](https://github.com/DCamma), [Demetrio Carrara](https://github.com/sgametrio) and [Roland Bapst](https://github.com/rbapst-tamedia)

## License

Apache 2 Licensed. See [LICENSE](< link to license file >) for full details.
