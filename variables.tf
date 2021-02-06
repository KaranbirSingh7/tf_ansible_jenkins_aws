variable "profile" {
  type        = string
  default     = "default"
  description = "default AWS profile from credentials file"
}

variable "webserver-port" {
  type        = number
  description = "webserver-port for application"
  default     = 8080
}

variable "dns-name" {
  type        = string
  description = "DNS name for website"
  default     = "cmcloudlab870.info."
}

variable "instance-type" {
  type        = string
  description = "size of jenkins server/workers"
  default     = "t3.micro"
}

variable "workers-count" {
  type    = number
  default = 2
}

variable "external_ip" {
  type        = string
  default     = "0.0.0.0/0"
  description = "your IP for SSH connection to VMs"
}


variable "region-master" {
  type    = string
  default = "us-east-1"
}

variable "region-worker" {
  type    = string
  default = "us-west-2"
}
