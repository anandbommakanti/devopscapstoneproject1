echo "Installing Docker.."
echo "Add Docker's official GPG key:"
apt-get update
apt-get install ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "Add the repository to Apt sources:"
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Installing Kubelet, Kubeadm..."
echo "Update the apt package index and install packages needed to use the Kubernetes apt repository:"
apt-get update
echo "apt-transport-https may be a dummy package; if so, you can skip that package"
apt-get install -y apt-transport-https ca-certificates curl
echo "Download the public signing key for the Kubernetes package repositories. The same signing key is used for all repositories so you can disregard the version in the URL:"
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "Add the appropriate Kubernetes apt repository:"
echo "This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list"
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
echo "Update the apt package index, install kubelet, kubeadm and kubectl, and pin their version:"
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

echo "Installing CRI with dockerd..."
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.4/cri-dockerd-0.3.4.amd64.tgz
tar xvf cri-dockerd-0.3.4.amd64.tgz
cd cri-dockerd
mkdir -p /usr/local/bin
install -o root -g root -m 0755 cri-dockerd /usr/local/bin/cri-dockerd
wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.service
wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.socket
install cri-docker.* /etc/systemd/system
sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
systemctl daemon-reload
systemctl enable --now cri-docker.socket
systemctl status cri-docker.socket

echo "Initializing the kubeadm along with Pod network..."
MASTER_PRIVATE_IP=$(ip addr show eth0 | awk '/inet / {print $2}' | cut -d/ -f1)
kubeadm init --apiserver-advertise-address="$MASTER_PRIVATE_IP" --pod-network-cidr=192.168.0.0/16 --cri-socket /run/cri-dockerd.sock
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown 1000:1000 $HOME/.kube/config

echo "Installing Celium Networking Plugin..."
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
cilium install --version 1.14.6
cilium status --wait
