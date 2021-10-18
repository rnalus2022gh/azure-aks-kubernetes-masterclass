#Log into the control plane node c1-cp1/master node c1-master1 
ssh aen@c1-cp1


#Listing and inspecting your cluster...helpful for knowing which cluster is your current context
kubectl cluster-info

--
vmadmin@c1-cp1:~$ kubectl cluster-info
Kubernetes control plane is running at https://172.16.94.4:6443
CoreDNS is running at https://172.16.94.4:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy   

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
--


#One of the most common operations you will use is get...
#Review status, roles and versions
kubectl get nodes
--
NAME       STATUS   ROLES                  AGE    VERSION
c1-cp1     Ready    control-plane,master   29m    v1.22.2
c1-node1   Ready    <none>                 4m2s   v1.22.2
--

#You can add an output modifier to get to *get* more information about a resource
#Additional information about each node in the cluster. 
kubectl get nodes -o wide
--
NAME       STATUS   ROLES                  AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE
   KERNEL-VERSION     CONTAINER-RUNTIME
c1-cp1     Ready    control-plane,master   30m     v1.22.2   172.16.94.4   <none>        Ubuntu 18.04.5 LTS   5.4.0-1025-azure   containerd://1.5.2
c1-node1   Ready    <none>                 4m23s   v1.22.2   172.16.94.5   <none>        Ubuntu 18.04.5 LTS   5.4.0-1025-azure   containerd://1.5.2
--

#Let's get a list of pods...but there isn't any running.
kubectl get pods 
--
No resources found in default namespace.
--

#True, but let's get a list of system pods. A namespace is a way to group resources together.
kubectl get pods --namespace kube-system
--
NAME                                       READY   STATUS    RESTARTS   AGE
calico-kube-controllers-75f8f6cc59-qnlmm   1/1     Running   0          27m
calico-node-crg6t                          1/1     Running   0          4m51s
calico-node-svwt7                          1/1     Running   0          27m
coredns-78fcd69978-6z7qw                   1/1     Running   0          30m
coredns-78fcd69978-szfg8                   1/1     Running   0          30m
etcd-c1-cp1                                1/1     Running   0          30m
kube-apiserver-c1-cp1                      1/1     Running   0          30m
kube-controller-manager-c1-cp1             1/1     Running   0          30m
kube-proxy-4mcvs                           1/1     Running   0          4m51s
kube-proxy-zcprd                           1/1     Running   0          30m
kube-scheduler-c1-cp1                      1/1     Running   0          30m
--

#Let's get additional information about each pod. 
kubectl get pods --namespace kube-system -o wide
--
NAME                                       READY   STATUS    RESTARTS   AGE    IP               NODE       
NOMINATED NODE   READINESS GATES
calico-kube-controllers-75f8f6cc59-qnlmm   1/1     Running   0          27m    192.168.13.195   c1-cp1     
<none>           <none>
calico-node-crg6t                          1/1     Running   0          5m6s   172.16.94.5      c1-node1   
<none>           <none>
calico-node-svwt7                          1/1     Running   0          27m    172.16.94.4      c1-cp1     
<none>           <none>
coredns-78fcd69978-6z7qw                   1/1     Running   0          30m    192.168.13.194   c1-cp1     
<none>           <none>
coredns-78fcd69978-szfg8                   1/1     Running   0          30m    192.168.13.193   c1-cp1     
<none>           <none>
etcd-c1-cp1                                1/1     Running   0          30m    172.16.94.4      c1-cp1     
<none>           <none>
kube-apiserver-c1-cp1                      1/1     Running   0          30m    172.16.94.4      c1-cp1     
<none>           <none>
kube-controller-manager-c1-cp1             1/1     Running   0          30m    172.16.94.4      c1-cp1     
<none>           <none>
kube-proxy-4mcvs                           1/1     Running   0          5m6s   172.16.94.5      c1-node1   
<none>           <none>
kube-proxy-zcprd                           1/1     Running   0          30m    172.16.94.4      c1-cp1     
<none>           <none>
kube-scheduler-c1-cp1                      1/1     Running   0          30m    172.16.94.4      c1-cp1     
<none>           <none>
--

#Now let's get a list of everything that's running in all namespaces
#In addition to pods, we see services, daemonsets, deployments and replicasets
kubectl get all --all-namespaces | more


#Asking kubernetes for the resources it knows about
#Let's look at the headers in each column. Name, Alias/shortnames, API Version 
#Is the resource in a namespace, for example StorageClass isn't and is available to all namespaces and finally Kind...this is the object type.
kubectl api-resources | more
--
NAME                              SHORTNAMES   APIVERSION                             NAMESPACED   KIND
bindings                                       v1                                     true         Binding 
componentstatuses                 cs           v1                                     false        ComponentStatus
configmaps                        cm           v1                                     true         ConfigMap
endpoints                         ep           v1                                     true         Endpoints
events                            ev           v1                                     true         Event   
limitranges                       limits       v1                                     true         LimitRange
namespaces                        ns           v1                                     false        Namespace
nodes                             no           v1                                     false        Node    
persistentvolumeclaims            pvc          v1                                     true         PersistentVolumeClaim
--More--
--


#You'll soon find your favorite alias
kubectl get no
--
NAME       STATUS   ROLES                  AGE     VERSION
c1-cp1     Ready    control-plane,master   32m     v1.22.2
c1-node1   Ready    <none>                 6m28s   v1.22.2
--


#We can easily filter using group
kubectl api-resources | grep pod
--
pods                              po           v1                                     true         Pod     
podtemplates                                   v1                                     true         PodTemplate
horizontalpodautoscalers          hpa          autoscaling/v1                         true         HorizontalPodAutoscaler
poddisruptionbudgets              pdb          policy/v1                              true         PodDisruptionBudget
podsecuritypolicies               psp          policy/v1beta1                         false        PodSecurityPolicy
--


#Explain an indivdual resource in detail
kubectl explain pod | more 
kubectl explain pod.spec | more 
kubectl explain pod.spec.containers | more 
kubectl explain pod --recursive | more 



#Let's take a closer look at our nodes using Describe
#Check out Name, Taints, Conditions, Addresses, System Info, Non-Terminated Pods, and Events
kubectl describe nodes c1-cp1 | more 
--
Name:               c1-cp1
Roles:              control-plane,master
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=c1-cp1
                    kubernetes.io/os=linux
                    node-role.kubernetes.io/control-plane=
                    node-role.kubernetes.io/master=
                    node.kubernetes.io/exclude-from-external-load-balancers=
Annotations:        kubeadm.alpha.kubernetes.io/cri-socket: /run/containerd/containerd.sock
                    node.alpha.kubernetes.io/ttl: 0
                    projectcalico.org/IPv4Address: 172.16.94.4/24
                    projectcalico.org/IPv4IPIPTunnelAddr: 192.168.13.192
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Mon, 18 Oct 2021 03:20:44 +0000
--More--
--

kubectl describe nodes c1-node1 | more
--
Name:               c1-node1
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=c1-node1
                    kubernetes.io/os=linux
Annotations:        kubeadm.alpha.kubernetes.io/cri-socket: /run/containerd/containerd.sock
                    node.alpha.kubernetes.io/ttl: 0
                    projectcalico.org/IPv4Address: 172.16.94.5/24
                    projectcalico.org/IPv4IPIPTunnelAddr: 192.168.222.192
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Mon, 18 Oct 2021 03:46:40 +0000
Taints:             <none>
Unschedulable:      false
Lease:
--More--
--


#Use -h or --help to find help
kubectl -h | more
kubectl get -h | more
kubectl create -h | more


#Ok, so now that we're tired of typing commands out, let's enable bash auto-complete of our kubectl commands
sudo apt-get install -y bash-completion
echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc
kubectl g[tab][tab] po[tab][tab] --all[tab][tab]

--
vmadmin@c1-cp1:~$ kubectl get pod --all-namespaces 
NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-75f8f6cc59-qnlmm   1/1     Running   0          32m
kube-system   calico-node-crg6t                          1/1     Running   0          9m20s
kube-system   calico-node-svwt7                          1/1     Running   0          32m
kube-system   coredns-78fcd69978-6z7qw                   1/1     Running   0          35m
kube-system   coredns-78fcd69978-szfg8                   1/1     Running   0          35m
kube-system   etcd-c1-cp1                                1/1     Running   0          35m
kube-system   kube-apiserver-c1-cp1                      1/1     Running   0          35m
kube-system   kube-controller-manager-c1-cp1             1/1     Running   0          35m
kube-system   kube-proxy-4mcvs                           1/1     Running   0          9m20s
kube-system   kube-proxy-zcprd                           1/1     Running   0          35m
kube-system   kube-scheduler-c1-cp1                      1/1     Running   0          35m
--

