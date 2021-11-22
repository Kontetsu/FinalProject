#!/bin/bash

echo "start script to automate the deploy of terraform and deploy application with ansible"

echo "start the terraform"
echo "Terraform plan and password of user "
echo randompass | base64 | terraform plan -out terra_vm.plan
echo "Terraform apply"
echo yes | terraform apply terra_vm.plan




