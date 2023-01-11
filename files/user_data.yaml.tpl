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
  #Kubespray
  - path: /opt/requirements.txt
    owner: root:root
    permissions: "0444"
    content: |
      ansible==5.7.1
      ansible-core==2.12.5
      cryptography==3.4.8
      jinja2==2.11.3
      netaddr==0.7.19
      pbr==5.4.4
      jmespath==0.9.5
      ruamel.yaml==0.16.10
      ruamel.yaml.clib==0.2.6
      MarkupSafe==1.1.1
packages:
  - python3-pip
  - jq
runcmd:
  - mv /opt/id_rsa* /home/${admin_user}/.ssh/
  - chown ${admin_user}:${admin_user} /home/${admin_user}/.ssh/id_rsa
  - chown ${admin_user}:${admin_user} /home/${admin_user}/.ssh/id_rsa.pub
  - pip3 install -r /opt/requirements.txt