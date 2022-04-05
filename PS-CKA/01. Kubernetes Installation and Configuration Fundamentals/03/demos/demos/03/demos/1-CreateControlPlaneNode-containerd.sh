###IMPORTANT###
#If you are using containerd, make sure docker isn't installed. 
#kubeadm init will try to auto detect the container runtime and at the moment 
#it if both are installed it will pick docker first.
ssh aen@c1-cp1


#0 - Creating a Cluster
#Create our kubernetes cluster, specify a pod network range matching that in calico.yaml! 
#Only on the Control Plane Node, download the yaml files for the pod network.
wget https://docs.projectcalico.org/manifests/calico.yaml


#Look inside calico.yaml and find the setting for Pod Network IP address range CALICO_IPV4POOL_CIDR, 
#adjust if needed for your infrastructure to ensure that the Pod network IP
#range doesn't overlap with other networks in our infrastructure.
vi calico.yaml


#Generate a default kubeadm init configuration file...this defines the settings of the cluster being built.
#If you get a warning about how docker is not installed...this is OK to ingore and is a bug in kubeadm
#For more info on kubeconfig configuration files see: 
#    https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#config-file
kubeadm config print init-defaults | tee ClusterConfiguration.yaml


#Inside default configuration file, we need to change four things.
#1. The IP Endpoint for the API Server localAPIEndpoint.advertiseAddress:
#2. nodeRegistration.criSocket from docker to containerd
#3. Set the cgroup driver for the kubelet to systemd, it's not set in this file yet, the default is cgroupfs
#4. Edit kubernetesVersion to match the version you installed in 0-PackageInstallation-containerd.sh
#5. Update the node name from node to the actual control plane node name, c1-cp1

#Change the address of the localAPIEndpoint.advertiseAddress to the Control Plane Node's IP address
sed -i 's/  advertiseAddress: 1.2.3.4/  advertiseAddress: 172.16.94.4/' ClusterConfiguration.yaml

#Set the CRI Socket to point to containerd
sed -i 's/  criSocket: \/var\/run\/dockershim\.sock/  criSocket: \/run\/containerd\/containerd\.sock/' ClusterConfiguration.yaml

#UPDATE: Added configuration to set the node name for the control plane node to the actual hostname
sed -i 's/  name: node/  name: c1-cp1/' ClusterConfiguration.yaml

#Set the cgroupDriver to systemd...matching that of your container runtime, containerd
cat <<EOF | cat >> ClusterConfiguration.yaml
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF


#Review the Cluster configuration file, update the version to match what you've installed. 
#We're using 1.21.0...if you're using a newer version update that here.
vi ClusterConfiguration.yaml


#Need to add CRI socket since there's a check for docker in the kubeadm init process, 
#if you don't you'll get this error...
#   error execution phase preflight: docker is required for container runtime: exec: "docker": executable file not found in $PATH
sudo kubeadm init \
    --config=ClusterConfiguration.yaml \
    --cri-socket /run/containerd/containerd.sock
# Rome - Join command
kubeadm join 172.16.94.4:6443 --token abcdef.0123456789abcdef \
        --discovery-token-ca-cert-hash sha256:5723090157d9972dd1080987d494112bc0cfe4d2de8193c16435a69794a8f2c9

kubeadm join 172.16.94.4:6443 --token abcdef.0123456789abcdef \
        --discovery-token-ca-cert-hash sha256:bbfde9ba876c5a27739c2aa453cc96220c6b225563bbd7a3a8765c9790c0dc1f


#Before moving on review the output of the cluster creation process including the kubeadm init phases, 
#the admin.conf setup and the node join command


#Configure our account on the Control Plane Node to have admin access to the API server from a non-privileged account.
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


#1 - Creating a Pod Network
#Deploy yaml file for your pod network. #May print a warning about PodDisruptionBudget it is safe to ignore for now.
kubectl apply -f calico.yaml


#Look for the all the system pods and calico pods to change to Running. 
#The DNS pod won't start (pending) until the Pod network is deployed and Running.
kubectl get pods --all-namespaces


#Gives you output over time, rather than repainting the screen on each iteration.
kubectl get pods --all-namespaces --watch


#All system pods should be Running
kubectl get pods --all-namespaces

NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-6fd7b9848d-k57ms   1/1     Running   0          3m23s
kube-system   calico-node-7p7hs                          1/1     Running   0          3m23s
kube-system   coredns-558bd4d5db-6m8wx                   1/1     Running   0          5m15s
kube-system   coredns-558bd4d5db-g7nh9                   1/1     Running   0          5m15s
kube-system   etcd-c1-cp1                                1/1     Running   0          5m23s
kube-system   kube-apiserver-c1-cp1                      1/1     Running   0          5m23s
kube-system   kube-controller-manager-c1-cp1             1/1     Running   0          5m23s
kube-system   kube-proxy-clncn                           1/1     Running   0          5m15s
kube-system   kube-scheduler-c1-cp1                      1/1     Running   0          5m23s



#Get a list of our current nodes, just the Control Plane Node/Master Node...should be Ready.
kubectl get nodes 




#2 - systemd Units...again!
#Check out the systemd unit...it's no longer crashlooping because it has static pods to start
#Remember the kubelet starts the static pods, and thus the control plane pods
sudo systemctl status kubelet.service 


#3 - Static Pod manifests
#Let's check out the static pod manifests on the Control Plane Node
ls /etc/kubernetes/manifests
etcd.yaml  kube-apiserver.yaml  kube-controller-manager.yaml  kube-scheduler.yaml


#And look more closely at API server and etcd's manifest.
sudo more /etc/kubernetes/manifests/etcd.yaml
sudo more /etc/kubernetes/manifests/kube-apiserver.yaml


#Check out the directory where the kubeconfig files live for each of the control plane pods.
ls /etc/kubernetes
admin.conf  controller-manager.conf  kubelet.conf  manifests  pki  scheduler.conf

ls -l /etc/kubernetes
total 36
-rw------- 1 root root 5591 Apr  5 14:35 admin.conf
-rw------- 1 root root 5623 Apr  5 14:35 controller-manager.conf
-rw------- 1 root root 1915 Apr  5 14:36 kubelet.conf
drwxr-xr-x 2 root root 4096 Apr  5 14:35 manifests
drwxr-xr-x 3 root root 4096 Apr  5 14:35 pki
-rw------- 1 root root 5571 Apr  5 14:35 scheduler.conf
