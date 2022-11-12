# Procedure
## Windows

CredSSp connexion:
`winrm set winrm/config/service '@{AllowUnencrypted="true"}'`
`winrm set winrm/config/service/auth '@{CredSSP="true"}' `

## Server
`pip install requests-credssp `

1. Requierment for Ansible:

apt-get update
apt-get upgrade
apt install software-properties-common
apt install python3-pip
pip install requests-credssp
apt install git
add-apt-repository ppa:ansible/ansible
apt update
apt install ansible

2. Install requirement package of ansible:
`ansible-galaxy collection install -r requirement.yml`

3. Launch playbook :
`ansible-playbook -i inventory.yml playbook.yml`