`winrm set winrm/config/service/auth '@{Basic="true"}'`
`winrm set winrm/config/service '@{AllowUnencrypted="true"}'`

credSSP:
`winrm set winrm/config/service/auth '@{CredSSP="true"}' `
Sur WSL:
`pip install requests-credssp `

--------
localisation fichier:
`cd /mnt/c/Users/Nico2/Repos/Ansible-Nicolas/`

Install or requirement of ansible:
`
ansible-galaxy collection install -r requirement.yml
`

Launch playbook :
`
ansible-playbook -i inventory.yml playbook.yml
`
Launch playbook with tags:
`ansible-playbook -i inventory.yml playbook.yml -t ChangeIp
`
## Cmd Install ansible WSL Ubuntu 20.04
`
sudo apt install software-properties-common
sudo add-apt-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible

` 

##Runner

sudo gitlab-runner register --url https://gitlab.com --registration-token GR1348941349nyJmxv5AZ9Z_Hoscm --name poei-virtual-machine --tag-list poeirunner  --executor docker --run-untagged --docker-image ubuntu:latest