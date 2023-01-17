#cloud-config
%{ if admin_user_password != "" ~}
chpasswd:
  list: |
     ${admin_user}:${admin_user_password}
  expire: False
%{ endif ~}
preserve_hostname: false
hostname: ${node_name}
users:
  - default    
  - name: node-exporter
    system: True
    lock_passwd: True
  - name: ${admin_user}
    ssh_authorized_keys:
      - "${external_public_key}"
write_files:
  #key
  - path: /opt/id_rsa
    owner: root:root
    permissions: "0600"
    content: |
      ${indent(6, internal_private_key)}
  - path: /opt/id_rsa.pub
    owner: root:root
    permissions: "0600"
    content: ${internal_public_key}
packages:
  - python3-pip
  - jq
runcmd:
  #Copy ssh key pair
  - mv /opt/id_rsa* /home/${admin_user}/.ssh/
  - chown ${admin_user}:${admin_user} /home/${admin_user}/.ssh/id_rsa
  - chown ${admin_user}:${admin_user} /home/${admin_user}/.ssh/id_rsa.pub
  #Install docker
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  - add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io
  - systemctl enable docker