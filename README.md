# FinalProject
=== Task 1 ===
1. Take a look into the mid-term project and recall how to deploy it to AKS
2. Create a Terraform configuration to create all required resources
3. Create a script (in your preferred language) that will create a new cluster for your application and deploy to AKS in it a single command
DONE

=== Task 2 ===
1. Create a Terraform configuration to create a custom virtual machine in Azure (of your chosen size and OS)
2. Use Ansible to install Nginx and JRE on the machine
3. Use Ansible to upload delivery files from mid-course project and start the application on the VM
4. Create a script to automate the whole flow
DONE

=== Task 3* ===
1. Create two clusters in AKS (preferably using code from Task 1) - test and prod done
2. Configure your CI to automatically deploy to test cluster
3. Create a manual deployment to prod cluster 


=== Task 4* ===
1.  Deploy a Jenkins server for automated deployments
2.  (3pt) Install Jenkins (https://www.jenkins.io/) 
3.  (6pt) Create a Jenkinsfile to build the Quiz app and automatically deploy it to an environment (in practice that's usually "test" or "staging", but in our case it's just one environment)
4.  
5.  (3pt) Move the Jenkins server to a separate virtual network and configure network peering between your app network and Jenkins network
6.  (3pt) Deploy at least two Jenkins Agents
7.  (Bonus: 3pt): Configure a job for manual deployment to an environment (in practice that usually "production")
8.  (Bonus: 6pt): Configure Jenkins to use Azure AD for authentication
9.  (Bonus: 12pt): Do all the above in automated way with a tool of your choice (Ansible / Terraform / Python / Kubernetes ...)

=== Extra ===

separate Kubernetes cluster as a test env
1. yes, or at least in two different containers (edited) 
2. each VM is connected to a network, which can be configured (both using Azure Portal and Terraform / CLI). By default they go to the same network, but you're free to connect them however you want
3.  the point is to use two networks, so that without configured network peering Jenkins server would not be able to connect to the cluster or, if you want to have a more realistic scenario:
4.  Jenkins server can be in one network, test cluster in the second one while Jenkins agents are in both this way you can deploy only from an agent and not from the server, this kind of deployment is usually done for security reasons
