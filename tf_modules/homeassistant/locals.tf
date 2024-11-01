locals {
  aws_region_country = local.cloudflare.aws_region == "eu-west-1" ? "IE" : "US"
}
