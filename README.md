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

# Server
## Raid mdadm
status: `cat /proc/mdstat`

## Update command
Portainer :
sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y && docker pull portainer/portainer-ee:alpine-sts && docker compose -f /home/docker/home-docker/Portainer/docker-compose.yml up -d --force-recreate && docker image prune --filter "dangling=true" -f

Agent:
sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y && docker pull portainer/agent:alpine-sts && docker compose -f /home/docker/home-docker/Portainer/agent/docker-compose.yml up -d --force-recreate && docker image prune --filter "dangling=true" -f

## Setting AMD passthrough
update grub */etc/default/grub* edit line *GRUB_CMDLINE_LINUX_DEFAULT*

`GRUB_CMDLINE_LINUX_DEFAULT="quiet splash amd_iommu=on iommu=pt pcie_acs_override=downstream,multifunction"`
