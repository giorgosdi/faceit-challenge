terraform {
  backend "s3" {
    bucket = "faceit-challenge-giorgos"
    key    = "terraform/state/terraform.tfstate"
    region = "eu-west-2"
    encrypt = true
  }
}

