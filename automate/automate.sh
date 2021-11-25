#!/bin/bash

echo "start script to automate the deploy of terraform and deploy jenkins with ansible"
echo "================================================================================="
echo "start the terraform"
terraform init
echo "Terraform plan and password of user "
echo randompass | base64 | terraform plan -out jenkinsvm.plan
echo "Terraform apply"
echo yes | terraform apply jenkinsvm.plan

echo "create inventary"
cat << EOF > ./jenkinsvm
[jenkinsvm]
EOF

echo "Get Terraform VM IP"
less /terraform.tfstate | grep public_ip_address | grep -oP "\d+.\d+.\d+.\d+" | head -n 1 >> jenkinsvm
echo "Get pass for users"
less terraform.tfstate | grep admin_password > hashedpass.txt
echo "Start install jenkins with ansible"
echo randompass | base64 | ansible-playbook -i jenkinsvm --ask-become-pass playbook_install_jenkins.yml
