provider "aws" {
  region                      = var.aws_region
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  
  s3_use_path_style           = true

  endpoints {
    ec2         = "http://localhost:4566"
    s3          = "http://localhost:4566"
    iam         = "http://localhost:4566"
    sts         = "http://localhost:4566"
    autoscaling = "http://localhost:4566"
    elb         = "http://localhost:4566"
    elbv2       = "http://localhost:4566"
  }
}

# 1. Network Module
module "network" {
  source      = "./modules/network"
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

# 2. Storage Module
module "storage" {
  source      = "./modules/storage"
  environment = var.environment
}

# 3. IAM Module
module "iam" {
  source             = "./modules/iam"
  environment        = var.environment
  storage_bucket_arn = module.storage.bucket_arn
}

# 4. Compute Module
module "compute" {
  source                    = "./modules/compute"
  environment               = var.environment
  vpc_id                    = module.network.vpc_id
  public_subnet_ids         = module.network.public_subnet_ids
  app_subnet_ids            = module.network.app_subnet_ids
  app_instance_profile_name = module.iam.app_instance_profile_name
}