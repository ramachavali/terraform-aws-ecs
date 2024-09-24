terraform {
  required_version = "~> 1.8.0"
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.5.0"
        }
	null = {
	     source = "hashicorp/null"
	     version = "~> 3.0"
    	}
   }	
}

provider "aws" {
    region                    = var.region
    shared_config_files       = [var.shared_config_files]
    shared_credentials_files  = [var.shared_credentials_files]
#    access_key = var.access_key
#    secret_key = var.secret_key
    profile                   = var.credential_profile
    default_tags {
		tags = var.default_tags
	}
}
