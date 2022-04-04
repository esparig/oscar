# Local Testing with kind

The easiest way to test the OSCAR platform locally is using [kind](https://kind.sigs.k8s.io/). Kind allows the deployment of Kubernetes clusters inside Docker containers and automatically configures `kubectl` to access them.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/), required by kind to launch the Kubernetes nodes on containers.
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) to communicate with the Kubernetes cluster.
- [Helm](https://helm.sh/docs/intro/install/) to easily deploy applications on Kubernetes.
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) to deploy the local Kubernetes cluster.

## Steps

### Create the cluster

To create a single node cluster with MinIO and Ingress controller ports locally accessible, run:

```sh
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 30300
    hostPort: 30300
    protocol: TCP
  - containerPort: 30301
    hostPort: 30301
    protocol: TCP
EOF
```

### Deploy NGINX Ingress

To enable Ingress support for accessing the OSCAR server, we must deploy the [NGINX Ingress](https://kubernetes.github.io/ingress-nginx/):

```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
```

### Deploy MinIO

OSCAR depends on [MinIO](https://min.io/) as storage provider and function trigger. The easy way to run MinIO in a Kubernetes cluster is by installing its [helm chart](https://github.com/minio/charts). To  install the helm MinIO repo and install the chart, run the following commands replacing `<MINIO_PASSWORD>` with a password:

```sh
helm repo add minio https://charts.min.io
helm install minio minio/minio --namespace minio --set rootUser=minio,rootPassword=<MINIO_PASSWORD>,service.type=NodePort,service.nodePort=30300,consoleService.type=NodePort,consoleService.nodePort=30301,mode=standalone,resources.requests.memory=512Mi,environment.MINIO_BROWSER_REDIRECT_URL=http://localhost:30301 --create-namespace
```

*Note that the deployment has been configured to use the rootUser `minio` and the specified password as rootPassword. The NodePort service type has been used in order to allow access from `http://localhost:30300` (API) and `http://localhost:30301` (Console).*

### Deploy NFS server provisioner

NFS server provisioner is required for the creation of `ReadWriteMany` PersistentVolumes in the kind cluster. This is needed by the OSCAR services to mount the volume with the [FaaS Supervisor](https://github.com/grycap/faas-supervisor) inside the job containers.

To deploy it you can use [this chart](https://github.com/kubernetes-sigs/nfs-ganesha-server-and-external-provisioner/tree/master/deploy/helm) executing:

```sh
helm repo add nfs-ganesha-server-and-external-provisioner https://kubernetes-sigs.github.io/nfs-ganesha-server-and-external-provisioner/
helm install nfs-server-provisioner nfs-ganesha-server-and-external-provisioner/nfs-server-provisioner
```

*Some Linux distributions may have [problems](https://github.com/kubernetes-sigs/kind/issues/1487#issuecomment-694920754) using the [NFS server provisioner](https://github.com/kubernetes-sigs/nfs-ganesha-server-and-external-provisioner) with kind due to its default configuration of kernel-limit file descriptors. To workaround it, please run `sudo sysctl -w fs.nr_open=1048576`.*

### Deploy OSCAR

First, create the `oscar` and `oscar-svc` namespaces by executing:

```sh
kubectl apply -f https://raw.githubusercontent.com/grycap/oscar/master/deploy/yaml/oscar-namespaces.yaml
```

Then, add the [grycap helm repo](https://github.com/grycap/helm-charts) and deploy by running the following commands replacing `<OSCAR_PASSWORD>` with a password of your choice and `<MINIO_PASSWORD>` with the MinIO rootPassword:

```sh
helm repo add grycap https://grycap.github.io/helm-charts/
helm install --namespace=oscar oscar grycap/oscar --set authPass=<OSCAR_PASSWORD> --set service.type=ClusterIP --set ingress.create=true --set volume.storageClassName=nfs --set minIO.endpoint=http://minio.minio:9000 --set minIO.TLSVerify=false --set minIO.accessKey=minio --set minIO.secretKey=<MINIO_PASSWORD>
```

Now you can access to the OSCAR web interface through `https://localhost` with user `oscar` and the specified password.

*Note that the OSCAR server has been configured to use the ClusterIP service of MinIO for internal communication. This blocks the MinIO section in the OSCAR web interface, so to download and upload files you must connect directly to MinIO (`http://localhost:30300`).*

### Delete the cluster

Once you have finished testing the platform, you can remove the local kind cluster by executing:

```sh
kind delete cluster
```

*Remember that if you have more than one cluster created, it may be required to set the `--name` flag to specify the name of the cluster to be deleted.*