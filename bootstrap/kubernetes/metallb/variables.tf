variable "kubernetes_namespace" {
  type = string
}

variable "metallb_name" {
  type = string
  default = "metallb"
}

variable "metallb_repository" {
  type = string
  default = "https://metallb.github.io/metallb"
}

variable "metallb_chart_name" {
  type = string
  default = "metallb"
}

variable "metallb_version" {
  type = string
  default = "0.14.3"
}

variable "metallb_ippool" {
  type = list(string)
  default = [ "172.21.255.200-172.21.255.250" ]
}