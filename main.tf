terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}


locals {
  DB_NAME   = "mydb"
  DB_USERNAME    = "foo"
  DB_PASSWORD  = "foobarbaz"
}


resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "${local.DB_NAME}"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "${local.DB_USERNAME}"
  password             = "${local.DB_PASSWORD}"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

output "rds_endpoint" {
  value = "${aws_db_instance.default.endpoint}"
}

output "host" {
  value = aws_elasticache_cluster.default.cache_nodes.0.address
}


resource "aws_elasticache_cluster" "default" {
  cluster_id           = "cluster-db"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  engine_version       = "6.2"
  port                 = 6379
}


resource "aws_instance" "app_server" {
  ami           = "ami-08116b9957a259459"
  instance_type = "t2.micro"
  key_name="testkey"
  user_data_base64 = base64encode("${templatefile("install.sh", {
    DB_NAME   = local.DB_NAME
    DB_USERNAME  = local.DB_USERNAME
    DB_PASSWORD  = local.DB_PASSWORD
    REDIS_ENDPOINT = "${aws_elasticache_cluster.default.cache_nodes.0.address}"
    DB_HOST =  "${aws_db_instance.default.endpoint}"
  })}")
  depends_on = [
    aws_db_instance.default,
    aws_elasticache_cluster.default
  ]
}



