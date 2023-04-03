# terraform-aws-lb module

Module for handling load balancers, listeners, target groups, route53 records creation. It also handles SSL certificates creation and validation through DNS. Besides the default target group, multiple target groups can be reached through path based routing from the same load balancer. By default, all http traffic is redirected to https. The load balancer is also protected via Okta as optional. 

Security groups are handled internally and only allow http and https traffic in.

## Usage
```hcl
module "lb" {
  source               = "github.com/tx-pts-dai/terraform-aws-lb"
  app_url              = "my-subdomain.domain"
  name                 = "my-deployment"
  vpc_id               = local.vpc_id
  subnets              = data.terraform_remote_state.core_infrastructure.outputs.public_subnets.ids
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

As optional, extra target groups can be set. Those will be reached through path based routing.
```hcl
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
```

For other optional inputs, see Inputs section

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
| <a name="input_default_target_group"></a> [default\_target\_group](#input\_default\_target\_group) | Definition of the default target group. The one reachable by default ('/'). | <pre>object({<br>    name     = string<br>    protocol = string<br>    port     = number<br>    health_check = object({<br>      path     = string<br>      port     = string<br>      protocol = string<br>      matcher  = string<br>    })<br>    tags = map(string)<br>  })</pre> | n/a | yes |
| <a name="input_log_bucket"></a> [log\_bucket](#input\_log\_bucket) | the S3 Bucket where to store the logs - if the bucekt name is empty logging is disabled | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | The name for the load balancer. | `string` | n/a | yes |
| <a name="input_okta_enabled"></a> [okta\_enabled](#input\_okta\_enabled) | if okta is enabled or not for the ALB | `bool` | `false` | no |
| <a name="input_path_target_groups"></a> [path\_target\_groups](#input\_path\_target\_groups) | Definition of the target groups. Each target group is accessed via path based routing. | <pre>list(object({<br>    name     = string<br>    protocol = string<br>    port     = number<br>    health_check = object({<br>      path     = string<br>      port     = string<br>      protocol = string<br>      matcher  = string<br>    })<br>    tags = map(string)<br>  }))</pre> | n/a | yes |
| <a name="input_secret_name"></a> [secret\_name](#input\_secret\_name) | the AWS Secret manager Secret name of the Secret where okta id and okta secret are stored. They should be stored as okta\_client\_id and okta\_client\_secret key | `string` | `""` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | A list of public subnet IDs for the load balancer. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to the load balancer and associated resources. | `map(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC in which to create the load balancer. | `string` | n/a | yes |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | the Route 53 zone id | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_load_balancer_dns_name"></a> [load\_balancer\_dns\_name](#output\_load\_balancer\_dns\_name) | The DNS of the load balancer. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is maintained by [Alfredo Gottardo](https://github.com/AlfGot), [David Beauvererd](https://github.com/Davidoutz), [Davide Cammarata](https://github.com/DCamma), [Demetrio Carrara](https://github.com/sgametrio) and [Roland Bapst](https://github.com/rbapst-tamedia)

## License

Apache 2 Licensed. See [LICENSE](< link to license file >) for full details.
