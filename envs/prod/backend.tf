terraform {
  # State bucket created by bootstrap/. Backend blocks cannot use variables or locals, so values are literal.
  backend "s3" {
    bucket       = "asthira-tfstate-dev"
    region       = "ap-south-1"
    key          = "envs/prod/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
