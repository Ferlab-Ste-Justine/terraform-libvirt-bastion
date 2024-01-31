#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if admin_user_password != "" ~}
ssh_pwauth: false
chpasswd:
  expire: False
  users:
    - name: ${ssh_admin_user}
      password: "${admin_user_password}"
      type: text
%{ endif ~}
preserve_hostname: false
hostname: ${hostname}
users:
  - default
  - name: ${ssh_admin_user}
    ssh_authorized_keys:
      - "${ssh_admin_public_key}"

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

runcmd:
  #Copy ssh key pair
  - mv /opt/id_rsa* /home/${ssh_admin_user}/.ssh/
  - chown ${ssh_admin_user}:${ssh_admin_user} /home/${ssh_admin_user}/.ssh/id_rsa
  - chown ${ssh_admin_user}:${ssh_admin_user} /home/${ssh_admin_user}/.ssh/id_rsa.pub
  #Install docker
%{ if install_dependencies ~}
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  - add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io
  - systemctl enable docker
%{ endif ~}