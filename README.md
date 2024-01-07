# Procedure Ansible
## Windows

CredSSp connexion:
` Enable-PSRemoting `
` winrm set winrm/config/service '@{AllowUnencrypted="true"}' `
` winrm set winrm/config/service/auth '@{CredSSP="true"}' `

## Server
`pip install requests-credssp `

1. Requierment for Ansible:

apt-get update
apt-get upgrade
apt install software-properties-common
apt install python3-pip
pip install "pywinrm>=0.3.0"
pip install requests-credssp
apt install git
add-apt-repository ppa:ansible/ansible
apt update
apt install ansible

2. Install requirement package of ansible:
`ansible-galaxy collection install -r requirement.yml`

3. Launch playbook :
`ansible-playbook -i inventory.yml playbook_rabbyt.yml`


# Dockerfile
create image :` docker build . -t rabbyt/ansible_ubuntu:latest `
push : `docker push rabbyt/ansible_ubuntu:latest`

if not login:
- go to docker hub \ connect \ Account setting \ Security => create token
- `docker login -u rabbyt` and on password paste token given