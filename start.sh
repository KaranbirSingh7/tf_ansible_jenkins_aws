rm -rf .terraform/

aws s3api create-bucket --bucket terraformstatebucket67

terraform init

terraform fmt

terraform validate

terraform plan

