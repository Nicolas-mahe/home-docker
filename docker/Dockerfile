FROM ubuntu:20.04

RUN apt-get update && \
    apt upgrade -y && \
    # apt dist-upgrade -y && \
    # apt autoremove -y && \
    apt -y install software-properties-common && \
    apt install -y python3-pip && \
    apt-add-repository --yes --update ppa:ansible/ansible && \
    apt install -y ansible && \
    pip install requests-credssp