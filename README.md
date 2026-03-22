# Procedure Ansible
## Windows

CredSSp connexion:
` Enable-PSRemoting `
` winrm set winrm/config/service '@{AllowUnencrypted="true"}' `
` winrm set winrm/config/service/auth '@{CredSSP="true"}' `

## Server
`pip install requests-credssp`

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

## Setting PCIE passthrough
update grub *nano /etc/default/grub* edit line *GRUB_CMDLINE_LINUX_DEFAULT*

Amd :
`GRUB_CMDLINE_LINUX_DEFAULT="quiet splash amd_iommu=on iommu=pt pcie_acs_override=downstream,multifunction"`

Intel :
`GRUB_CMDLINE_LINUX_DEFAULT="quiet splash amd_iommu=on iommu=pt pcie_acs_override=downstream,multifunction"`

and run *update-grub* or *proxmox-boot-tool refresh* on Proxmox v9

## Setting a hard disk in passthroug
1. identify disk with `find /dev/disk/by-id/ -type l|xargs -I{} ls -l {}|grep -v -E '[0-9]$' |sort -k11|cut -d' ' -f9,10,11,12`

    example:
    ```bash
    /dev/disk/by-id/ata-Samsung_SSD_860_EVO_500GB_S3Z2NB0M478767D -> ../../sda
    /dev/disk/by-id/wwn-0x5002538e40f7ef4c -> ../../sda
    /dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S6PYNU0Y308180N -> ../../sdb
    /dev/disk/by-id/wwn-0x5002538f5532d739 -> ../../sdb
    ```
2. set disk in passthrough with `qm set <vmid> -scsiX /path/to/disk`

    example:
    `root@pdcpd1004sindri:~# qm set 101 -scsi1 /dev/disk/by-id/ata-Samsung_SSD_860_EVO_500GB_S3Z2NB0M478767D`