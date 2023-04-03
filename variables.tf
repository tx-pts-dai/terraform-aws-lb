variable "name" {
  description = "The name for the load balancer."
  type        = string
}

variable "path_target_groups" {
  description = "Definition of the target groups. Each target group is accessed via path based routing."
  type = list(object({
    name     = string
    protocol = string
    port     = number
    health_check = object({
      path     = string
      port     = string
      protocol = string
      matcher  = string
    })
    tags = map(string)
  }))
}


variable "default_target_group" {
  description = "Definition of the default target group. The one reachable by default ('/')."
  type = object({
    name     = string
    protocol = string
    port     = number
    health_check = object({
      path     = string
      port     = string
      protocol = string
      matcher  = string
    })
    tags = map(string)
  })
}

variable "subnets" {
  description = "A list of public subnet IDs for the load balancer."
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to apply to the load balancer and associated resources."
  type        = map(string)
}

variable "vpc_id" {
  description = "The ID of the VPC in which to create the load balancer."
  type        = string
}

variable "app_url" {
  description = "the domain name of the Application"
  type        = string
}

variable "zone_id" {
  description = "the Route 53 zone id"
  type        = string
}

variable "okta_enabled" {
  description = "if okta is enabled or not for the ALB"
  type        = bool
  default     = false
}

variable "secret_name" {
  description = "the AWS Secret manager Secret name of the Secret where okta id and okta secret are stored. They should be stored as okta_client_id and okta_client_secret key"
  type        = string
  default     = ""
}

variable "log_bucket" {
  description = "the S3 Bucket where to store the logs - if the bucekt name is empty logging is disabled "
  type        = string
  default     = ""
}

/*
  target_groups = [
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
        Name = "Orchestrator"
        Environment = "Production"
      }
    },
    {
      name = "api"
      protocol = "HTTP"
      port = 8080
      health_check = {
        path = "/health"
        port = "traffic-port"
        protocol = "HTTP"
        matcher = "200"
      }
      tags = {
        Name = "Admin"
        Environment = "Production"
      }
    }
  ]
  */
