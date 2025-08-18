variable "datacenter" {}
variable "payload_image" {}
variable "payload_command" {
  type    = list(string)
  default = []
}
variable "payload_port" {
  type    = number
  default = 0
}
variable "payload_id" {}
variable "consul_http_addr" {}
variable "consul_http_token" {
  default = ""
}
variable "task_cpu" {
  type    = number
  default = 256
}
variable "task_memory" {
  type    = number
  default = 512
}
