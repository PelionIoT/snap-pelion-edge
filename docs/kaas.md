# Getting started

Prerequisites:

- A [Pelion account](https://portal.mbedcloud.com).
- [kubectl version `1.14.3`](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
- The pelion-edge snap installed to an ubuntu-core 16 gateway or virtual machine (VM):
   
  ```bash
  $ kubectl get nodes
  NAME                               STATUS    ROLES    AGE    VERSION
  016f324f1753162e4903427d03c00000   Ready     <none>   7d7h
  ```
   
   Output like this will show your gateways. Gateways that are running are `Ready`.
   
- The pelion-edge snap registered to your Pelion account.
   
1. Generate an API key.

   1. Log in to the [Pelion Portal](https://portal.mbedcloud.com).
   1. Navigate to the Access Management section in the menu on the left.
   1. Click on **API keys**.
   1. Click on the **New API Key** button.
   1. Wait for the dialog box to appear.
   1. After the dialog box appears, enter a name for your API key.
   1. Select the **Administrators** group.
   1. Click **Create API Key**.
   1. Copy the API key to your clipboard. You will use this in the next step: creating a kubeconfig file.
   
1. Create a `kubeconfig` file.

   Most Kubernetes tools, including `kubectl`, require a `kubeconfig` file that contains cluster addresses and credentials for communicating with those clusters.
   
   1. Use this template to generate a file:
   
   ```yaml
   apiVersion: v1
   clusters:
   - cluster:
       server: https://edge-k8s.us-east-1.mbedcloud.com
     name: edge-k8s
   contexts:
   - context:
       cluster: edge-k8s
       user: edge-k8s
     name: edge-k8s
   current-context: edge-k8s
   kind: Config
   preferences: {}
   users:
   - name: edge-k8s
     user:
       token: YOUR API KEY HERE
   ```
   
   1. Fill in your API key where it says **YOUR API KEY HERE**.
   1. Put this file in your home directory under `~/.kube/config`. If you already have a kubeconfig file, you can merge the cluster, context and user into that file. To select the `edge-k8s` context, use the `kubectl config` command:
   
   ```bash
   $ kubectl config use-context edge-k8s
   ```

1. Make sure `kubectl` can talk to `edge-k8s` by listing nodes in your account to see which gateways are connected.

## Deploying a pod

This example illustrates how to deploy a basic `Pod` using `kubectl` and how to use the `kubectl logs` and `kubectl exec` command to inspect and interact with the `Pod`.

1. Copy this YAML to a file `pod.yaml`, and replace `nodeName` with your node's ID:

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: test-pod
   spec:
     automountServiceAccountToken: false
     hostname: test-pod
     nodeName: 016f324f1753162e4903427d03c00000
     containers:
     - name: client
       image: alpine:3.9
       command: ["/bin/sh"]
       args: ["-c","echo 'hello'; sleep 6000000"]
   ```

1. Deploy this Pod:

   ```
   $ kubectl create -f pod.yaml
   pod/test-pod created
   $ kubectl get pods
   NAME       READY   STATUS              RESTARTS   AGE
   test-pod   0/1     ContainerCreating   0          9s
   $ kubectl get pods
   NAME       READY   STATUS    RESTARTS   AGE
   test-pod   1/1     Running   0          85s
   ```

1. View Logs:

   ```
   $ kubectl logs test-pod
   hello
   ```

1. Execute commands:

   ```
   $ kubectl exec -it test-pod -- sh
   / # echo "hi"
   hi
   / # ls
   bin    dev    etc    home   lib    media  mnt    opt    proc   root   run    sbin   srv    sys    tmp    usr    var
   / # exit
   $
   ```

## Configuring a pod

You can use ConfigMaps and Secrets to configure Pods. This example creates a ConfigMap and Secret and shows how you can mount them as volumes inside a Pod.

1. Create a `ConfigMap` in `my-cm.yaml`:

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: my-cm
   data:
     example.txt: my config map
   ```

1. Create a `Secret` in `my-secret.yaml`:

   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: my-secret
   type: Opaque
   data:
     example.txt: bXkgc2VjcmV0Cg==
   ```

1. Use `kubectl` to create the `ConfigMap` and `Secret`:

   ```
   $ kubectl create -f my-cm.yaml 
   configmap/my-cm created
   $ kubectl create -f my-secret.yaml 
   secret/my-secret created
   ```

1. Create a `Pod` in `pod.yaml`:

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: test-pod
   spec:
     automountServiceAccountToken: false
     containers:
     - args:
       - -c
       - echo "$(cat /my_secret/example.txt /my_cm/example.txt)"; sleep 6000000
       command:
       - /bin/sh
       image: alpine:3.9
       name: client
       volumeMounts:
       - mountPath: /my_secret
         name: examplesecret
       - mountPath: /my_cm
         name: examplecm
     hostname: test-pod
     nodeName: 016f324f1753162e4903427d03c00000
     volumes:
     - name: examplecm
       configMap:
         name: my-cm
     - name: examplesecret
       secret:
         secretName: my-secret
   ```

1. Use `kubectl` to create the `Pod`.

1. View Logs:

   ```
   $ kubectl logs test-pod
   my secret
   my config map
   ```

1. Execute commands:

   ```
   $ kubectl exec -it test-pod -- sh
   / # ls /my_secret/example.txt 
   /my_secret/example.txt
   / # cat /my_secret/example.txt 
   my secret
   / # ls /my_cm/example.txt 
   /my_cm/example.txt
   / # cat /my_cm/example.txt 
   my config map/ # exit
   $
   ```

## Service discovery

Pods often represent different applications on a gateway that need to talk to one another. Rather than using a static IP address for one of the Pods, use a Pod's hostname when addressing it and use DNS for service discovery.

1. Create test-pod:

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: test-pod
   spec:
     automountServiceAccountToken: false
     hostname: test-pod
     nodeName: 016f324f1753162e4903427d03c00000
     containers:
     - name: client
       image: alpine:3.9
       command: ["/bin/sh"]
       args: ["-c","echo 'hello'; sleep 6000000"]
     restartPolicy: Always
   ```

1. Create nginx pod:

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: nginx
   spec:
     automountServiceAccountToken: false
     containers:
     - image: nginx:1.17
       name: nginx
     hostname: nginx
     nodeName: 016ec82cae2500000000000100169037
     restartPolicy: Always
   ```

1. Execute a shell inside the `test-pod`. The host name `nginx` resolves to the IP address of the nginx Pod. After installing curl inside `test-pod`, you can make an HTTP request to the nginx Pod using a curl command:
   
   ```
   $ kubectl exec -it test-pod -- sh
   / # nslookup
   BusyBox v1.29.3 (2019-01-24 07:45:07 UTC) multi-call binary.
   
   Usage: nslookup HOST [DNS_SERVER]
   
   Query DNS about HOST
   / # nslookup nginx
   nslookup: can't resolve '(null)': Name does not resolve
   
   Name:      nginx
   Address 1: 10.0.0.2    k8s_POD_nginx_default_140806bb-30cc-11ea-83d4-627982ffddac_0.edgenet
   / # apk add curl
   fetch http://dl-cdn.alpinelinux.org/alpine/v3.9/main/x86_64/   APKINDEX.tar.gz
   fetch http://dl-cdn.alpinelinux.org/alpine/v3.9/community/x86_64/   APKINDEX.tar.gz
   (1/5) Installing ca-certificates (20190108-r0)
   (2/5) Installing nghttp2-libs (1.35.1-r1)
   (3/5) Installing libssh2 (1.9.0-r1)
   (4/5) Installing libcurl (7.64.0-r3)
   (5/5) Installing curl (7.64.0-r3)
   Executing busybox-1.29.3-r10.trigger
   Executing ca-certificates-20190108-r0.trigger
   OK: 7 MiB in 19 packages
   / # curl
   curl: try 'curl --help' or 'curl --manual' for more information
   / # curl http://nginx
   <!DOCTYPE html>
   <html>
   <head>
   <title>Welcome to nginx!</title>
   <style>
       body {
           width: 35em;
           margin: 0 auto;
           font-family: Tahoma, Verdana, Arial, sans-serif;
       }
   </style>
   </head>
   <body>
   <h1>Welcome to nginx!</h1>
   <p>If you see this page, the nginx web server is successfully installed    and
   working. Further configuration is required.</p>
   
   <p>For online documentation and support please refer to
   <a href="http://nginx.org/">nginx.org</a>.<br/>
   Commercial support is available at
   <a href="http://nginx.com/">nginx.com</a>.</p>
   
   <p><em>Thank you for using nginx.</em></p>
   </body>
   </html>
   / # exit
   ```

## Supported resources

- DaemonSet.
- Nodes.
- Pods.
- ConfigMaps.
- Secrets.
