#!/bin/bash

echo "start script to automate the deploy of terraform and deploy jenkins with ansible"
echo "================================================================================="
echo "start the terraform"
terraform init
echo "Terraform plan and password of user "
echo randompass | base64 | terraform plan -out jenkinsagent.plan
echo "Terraform apply"
echo yes | terraform apply jenkinsagent.plan

echo "create inventary"
cat << EOF > jenkinsagent
[jenkinsagent]
EOF

echo "Get Terraform VM IP"
less terraform.tfstate | grep public_ip_address | grep -oP "\d+.\d+.\d+.\d+" | head -n 1 >> jenkinsagent
echo "Get pass for users"
less terraform.tfstate | grep admin_password > hashedpass.txt
echo "Start install jenkins with ansible"
echo randompass | base64 | ansible-playbook -i jenkinsagent --ask-become-pass docker_playbook.yml -e 'ansible_python_interpreter=/usr/bin/python3'


# ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDU6/7PgRYxcH62kJv4Ctme+A3lCRDsuMmvqnhd/VxDZaPkDUduYKktb9IfwiHT4alrdpRUfpVdJ8Zhc8Oo7ZIsvVbu92dWxGvTUIyiEhgQSedbnU9IVjBKtefCHilGeW1pOXIg2eeXtgMXiVpLFvj9UFPdDlQzkv13405n7C/64fAbrJvuDUiirm+0EEGmmw0otnx4vjqJL09w9oW9xxhvXmrGZQ+29nKBeH9tawyz7eVKD8YAmb91CGDrNUJMtPzsIU+TAhGJeZi+OCIJ1z9ENnOeRcrZ3HdJBP76jl/pslGW6TwQs2WZzJhl5b1yW8CRN2+N/Ec0eKt9Xspn/tKD root@jenkins


# docker run -d --rm --name=agent1 -p 22:22 \
# -e "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDin0CtvHEHOuCdJf1FhO5N3F4PvAphaGKh0sykYLhm3OIMCff4Bg8XHqrkSRxU8ak1m9rtKEGuJR3AAGUbK3XnOvszXxBZMYNa5C1xikXPOUIMOYGc2J5SBsQoq2BFaX0hWZVXh+URJQN5L+yUInYIfdniggwxz2IUoApdKdcNW1wr4Zhm4ijmxiw6YxTiGgRpq57Sd5j9YbcwCLB06FdHo80qoNyaduMCGQqeGs48vMvTnUH/tcnHD2NbHschFVXSJNs4QOZq0f0GhPutHdDIkZapWDXxwbyjOgUNSaZwLIE+m6XQ+WUY89EWzGoU+Ga3n/rRi7/eEG3Ay3npvEX root@jenkins" \
# jenkins/ssh-agent:alpine

# docker run -d -i --rm --name agent1 -p 22:22 \
# --init -v agent1-workdir:/home/jenkins/agent java -jar /usr/share/jenkins/agent.jar -workDir /home/jenkins/agent jenkins/ssh-agent:alpine