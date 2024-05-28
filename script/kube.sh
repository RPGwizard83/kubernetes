#!/bin/bash
#---------------------------------------------------------------------------------------------------

#--[1.1]- Modulos necesarios
tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF


sudo modprobe overlay
sudo modprobe br_netfilter
#--[1.2]- Forzar el trafico IPv4 y IPv6 para pasar a través de iptables.


#-- Se crea un archivo sysctl en /etc/sysctl.d/99-kubernetes-cri.conf que contiene las siguientes líneas:


tee /etc/sysctl.d/99-kubernetes-cri.conf <<EOT
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOT


sudo sysctl net.ipv4.ip_forward=1
#--sysctl se utiliza para modificar la variable del kernel de linux.
#--Se puede utilizar el comando sysctl -a para comprobar todos los valores.
sudo sysctl --system


#--[1.3]- Deshabilitar el firewall
sudo ufw disable


#--[1.4]- Deshabilitar la memoria swap  
sudo swapoff -a  
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab  


#--[1.5]- Instalar paquetes necesarios
apt-get update  
apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common


###########################################################################
#--[2]- Instalar containerd
###########################################################################
#--[2.1]- Instalacion containerd
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"


sudo apt update
sudo apt install -y containerd.io
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml


#--[2.2]- Resetear y encender los servicios de containerd
sudo systemctl restart containerd
sudo systemctl enable containerd


###########################################################################
#--[3]- Instalar Kubectl, Kubeadm and Kubelet
###########################################################################
#--[3.1]- Añadir keys y repositorio
curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg  
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"  


curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list




#--[3.2]- Instalar kubelet kubeadm kubectl
sudo apt update
sudo apt install -y kubelet kubeadm kubectl


#--[3.3]- Detener la actualización automática
apt-mark hold kubelet kubeadm kubectl 