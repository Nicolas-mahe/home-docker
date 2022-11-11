# Fichier Yaml afin de d'automatiser la création de la machine virtuel Windows Server 2019 d'un serveur hebergeant une application C#.Net accecible via le HTTP

## Install a Virtual Serveur on ESXI Win2k2019:

Activate the ansible connection:

1. Setup Interface with public IP: 
Put Mac adresse on ESXI : 02:00:00:BF:47:CB
Ip :149.202.37.191
gateway : 51.210.0.254
Netmask : 255.255.255.255
DNS : 213.186.33.99


2. Open port 5985 in FireWall for WinRM connection

3. Cmd activate WinRM :

Basic :
`winrm set winrm/config/service/auth '@{Basic="true"}'`
`winrm set winrm/config/service '@{AllowUnencrypted="true"}'`

credSSP:
`winrm set winrm/config/service/auth '@{CredSSP="true"}' `
Sur WSL:
`pip install requests-credssp `

4. Create account service "Ansible" + **allow administrator acces**

--------
localisation fichier:
`
cd /mnt/c/Users/Nicolas/source/repos/ansible-nicolas/
cd /mnt/c/Users/RaBByT/Repos_Git/ansible-nicolas/
`

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