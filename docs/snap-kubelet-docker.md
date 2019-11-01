# Snap, Kubelet, and Docker
Kubelet requires a ["container runtime"](https://kubernetes.io/docs/setup/production-environment/container-runtimes/) to manage containers for Pods.
Docker is one of the most common container runtimes and is what we chose to pair with kubelet for our build. We encountered several obstacles while
trying to integrate kubelet, docker, and snap. This document outlines the process we went through to arrive at our current setup including the 
problems and their solutions at each step.

## Using The Official Docker Snap
Before knowing anything about the restrictions the snap environment enforced we considered the tradeoffs between packaging docker inside our snap
vs using the off-the-shelf docker snap. We considered that packaging docker with our snap might have undesirable side-effects if a user were to 
install our snap on a system where docker was already installed. After all, our snap may not be the only user of docker on that system and we didn't 
want to require a user with docker already running to uninstall their docker daemon and use ours instead. It was unclear how running two instances 
of docker on a system would affect it and what kind of isolation snaps provided. We settled on using the off-the-shelf docker snap and keeping our
software in a different snap. This was appealing because we avoided possible conflicts with other docker daemons, make our build process easier,
and make our snap smaller. The task seemed simple enough but quirks of snap and the isolation it provides prevents this approach from being possible.

### Problem 1: Apparmor Profiles - Ptrace
When kubelet starts up it talks to a kubernetes API server in the cloud to discover which Pods it has been assigned. A Pod is basically a specification for a set of containers that share the same networking namespace and the parameters they should be run with. After kubelet receives a Pod assignment from the API server it asks docker to start up a [pause container](https://www.ianlewis.org/en/almighty-pause-container) for this Pod which it uses to initialize the Pod's networking namespace that all other containers will belong to. All containers in a Pod will therefore share an IP address and will be able to talk to each other over localhost. CNI, or container networking interface, plugins are responsible for initializing the networking interfaces for a Pod when it is starting up. CNI plugins just executables started up by kubelet when it wants to configure the network interfaces of a new Pod. The loopback CNI plugin sets up the loopback interface for a Pod. Originally when trying to run the pelion-edge snap alongside the official docker snap the kubelet logs showed these errors while trying to deploy a Pod.

```
Aug 21 18:37:24 localhost.localdomain pelion-edge.kubelet[10990]: E0821 18:37:24.426195   10990 cni.go:309] Error adding default_test-pod-016c6de7e4f7000000000001001003c1/2017642be9f6094dec4997f658cc4187ade60eb193fa1b8ef1f064b988502412 to network loopback/cni-loopback: failed to Statfs "/proc/14361/ns/net": permission denied
...
Aug 21 18:37:24 localhost.localdomain pelion-edge.kubelet[10990]: E0821 18:37:24.896277   10990 remote_runtime.go:96] RunPodSandbox from runtime service failed: rpc error: code = Unknown desc = failed to set up sandbox container "2017642be9f6094dec4997f658cc4187ade60eb193fa1b8ef1f064b988502412" network for pod "test-pod-016c6de7e4f7000000000001001003c1": NetworkPlugin cni failed to set up pod "test-pod-016c6de7e4f7000000000001001003c1_default" network: failed to Statfs "/proc/14361/ns/net": permission denied
Aug 21 18:37:24 localhost.localdomain pelion-edge.kubelet[10990]: E0821 18:37:24.896367   10990 kuberuntime_sandbox.go:65] CreatePodSandbox for pod "test-pod-016c6de7e4f7000000000001001003c1_default(2032456b-c2b8-11e9-9621-263fe8375b9d)" failed: rpc error: code = Unknown desc = failed to set up sandbox container "2017642be9f6094dec4997f658cc4187ade60eb193fa1b8ef1f064b988502412" network for pod "test-pod-016c6de7e4f7000000000001001003c1": NetworkPlugin cni failed to set up pod "test-pod-016c6de7e4f7000000000001001003c1_default" network: failed to Statfs "/proc/14361/ns/net": permission denied
Aug 21 18:37:24 localhost.localdomain pelion-edge.kubelet[10990]: E0821 18:37:24.896412   10990 kuberuntime_manager.go:662] createPodSandbox for pod "test-pod-016c6de7e4f7000000000001001003c1_default(2032456b-c2b8-11e9-9621-263fe8375b9d)" failed: rpc error: code = Unknown desc = failed to set up sandbox container "2017642be9f6094dec4997f658cc4187ade60eb193fa1b8ef1f064b988502412" network for pod "test-pod-016c6de7e4f7000000000001001003c1": NetworkPlugin cni failed to set up pod "test-pod-016c6de7e4f7000000000001001003c1_default" network: failed to Statfs "/proc/14361/ns/net": permission denied
Aug 21 18:37:24 localhost.localdomain pelion-edge.kubelet[10990]: E0821 18:37:24.896516   10990 pod_workers.go:190] Error syncing pod 2032456b-c2b8-11e9-9621-263fe8375b9d ("test-pod-016c6de7e4f7000000000001001003c1_default(2032456b-c2b8-11e9-9621-263fe8375b9d)"), skipping: failed to "CreatePodSandbox" for "test-pod-016c6de7e4f7000000000001001003c1_default(2032456b-c2b8-11e9-9621-263fe8375b9d)" with CreatePodSandboxError: "CreatePodSandbox for pod \"test-pod-016c6de7e4f7000000000001001003c1_default(2032456b-c2b8-11e9-9621-263fe8375b9d)\" failed: rpc error: code = Unknown desc = failed to set up sandbox container \"2017642be9f6094dec4997f658cc4187ade60eb193fa1b8ef1f064b988502412\" network for pod \"test-pod-016c6de7e4f7000000000001001003c1\": NetworkPlugin cni failed to set up pod \"test-pod-016c6de7e4f7000000000001001003c1_default\" network: failed to Statfs \"/proc/14361/ns/net\": permission denied"
```
This is really the same error bubbling up through the stack. The core issue here is in the first log message where the loopback CNI plugin is unable to complete successfully due to a permissions error. This error is generated in the [github.com/containernetworking/plugins/package/ns](https://github.com/containernetworking/plugins/blob/485be65581341430f9106a194a98f0f2412245fb/pkg/ns/ns_linux.go#L122) package, a dependency of the loopback CNI binary where it makes a Statfs system call on /proc/14361/ns/net where 14361 is the PID of the pause container process for the new Pod. Ultimately the Pod creation fails and kubelet will tear everything down. The Pod remains in the ContainerCreating state in the API server as kubelet spins trying and failing again and again. This error occurs whether the pelion-edge snap is running with devmode, or strict isolation. We used the snappy-debug tool to see if apparmor is denying any system calls and to get some more information about why they are rejected.

```bash
barheadedgoose@localhost:~$ sudo snappy-debug.security scanlog | grep DENIED
INFO: Detected Ubuntu Core. For best results, redirect journalctl. Eg:
INFO: $ sudo journalctl --output=short --follow --all | sudo snappy-debug
WARN: could not find log mark, is syslog enabled?
Log: apparmor="DENIED" operation="ptrace" profile="docker-default" pid=1666 comm="loopback" requested_mask="tracedby" denied_mask="tracedby" peer="snap.pelion-edge.kubelet"
Log: apparmor="DENIED" operation="ptrace" profile="docker-default" pid=1824 comm="loopback" requested_mask="tracedby" denied_mask="tracedby" peer="snap.pelion-edge.kubelet"
Log: apparmor="DENIED" operation="ptrace" profile="docker-default" pid=1977 comm="loopback" requested_mask="tracedby" denied_mask="tracedby" peer="snap.pelion-edge.kubelet"
Log: apparmor="DENIED" operation="ptrace" profile="docker-default" pid=2139 comm="loopback" requested_mask="tracedby" denied_mask="tracedby" peer="snap.pelion-edge.kubelet"
Log: apparmor="DENIED" operation="ptrace" profile="docker-default" pid=2285 comm="loopback" requested_mask="tracedby" denied_mask="tracedby" peer="snap.pelion-edge.kubelet"
```

These seemed to be correlated with the "permission denied" errors seen in the kubelet logs, but in order to confirm this theory kubelet needed to be run with strace so that we could match the pid listed in the snappy-debug logs with the PIDs of the loopback CNI processes. Snaps can be run in the foreground instead of as a daemon. First the daemon needs to be stopped.

```bash
barheadedgoose@localhost:~$ sudo service snap.pelion-edge.kubelet stop
```

We can start the snap in the foreground with strace enabled. Strace lets us trace the child processes and threads created by kubelet and see which system calls they are making.

```bash
barheadedgoose@localhost:~$ sudo snap run --strace="-f -o kubelet.strace.out" pelion-edge.kubelet
```

A new file is created for each child process with a log of the system calls it is making. In our case we spot checked a few of the PIDs listed in the snappy-debug log and compared them to the the strace output.

```
# kubelet.strace.out.1666
...
execve("/snap/pelion-edge/x1/wigwag/system/opt/cni/bin/loopback", ["/snap/pelion-edge/x1/wigwag/syst"...], 0xc001130dc0 /* 40 vars */) = 0
...
statfs("/proc/1606/ns/net", 0xc0000bbb40) = -1 EACCES (Permission denied)
...
```

```
# kubelet.strace.out.1824
...
execve("/snap/pelion-edge/x1/wigwag/system/opt/cni/bin/loopback", ["/snap/pelion-edge/x1/wigwag/syst"...], 0xc00122a160 /* 40 vars */) = 0
...
statfs("/proc/1761/ns/net", 0xc0000b9b40) = -1 EACCES (Permission denied)
...
```

This confirms that the apparmor errors in the log correspond with the loopback CNI invocations made by kubelet and that the docker-default apparmor policy is responsible for rejecting the statfs request.

#### docker-default Policy
Snap creates apparmor policies for snaps based on the snap's plug and slot settings. Apparmor policies for devmode snaps are put into complain mode where profile violations are reported but not enforced. Snap sets the apparmor profile for strict snaps to enforce mode where the profile is enforced. Completely separate from that Docker applies its own docker-default apparmor policy to containers it creates. By itself the docker-default profile doesn't do anything that would cause problems for kubelet, but the docker-snap build process actually patches dockerd's code to edit the template used to generate the docker-default apparmor profile.

```
+ # Snap based docker distribution accesses
+ # Allow the daemon to trace/signal containers
+ ptrace (readby, tracedby) peer="snap.docker.dockerd",
+ signal (receive) peer="snap.docker.dockerd",
+ # Allow container processes to signal other container processes
+ signal (send, receive) peer=docker-default,
```

These changes seem like they would be responsible for the permissions problems. A possible fix would be to edit this patch so that snap.pelion-edge.kubelet is added as a peer. This is where I'm unsure, however, since I don't really know too much about how apparmor profiles and ptrace work and how ptrace relates to system calls like statfs. My initial idea was to change the patch to something like this and rebuild the docker-snap myself:

```
+ # Snap based docker distribution accesses
+ # Allow the daemon to trace/signal containers
+ ptrace (readby, tracedby) peer="snap.docker.dockerd",

+ ptrace (readby, tracedby) peer="snap.pelion-edge.kubelet",
+ signal (receive) peer="snap.docker.dockerd",

+ signal (receive) peer="snap.pelion-edge.kubelet",
+ # Allow container processes to signal other container processes
+ signal (send, receive) peer=docker-default,
```

Before changing anything, however, I just built an unmodified docker snap from this repository: [https://git.launchpad.net/~docker/+git/snap/](https://git.launchpad.net/~docker/+git/snap/). It was hard to determine which commit they built the latest official snap from but I just built from the latest commit on master where the docker version matched what I had installed before. I got that built, uninstalled the official docker snap, then installed this snap instead. To my surprise, it worked. The snap I built from the unmodified docker-snap repository worked without any permissions problems. That's where I stopped looking into the problem. This configuration seems to work for now. The only caveat being that we need to build the docker snap ourselves.

Although I got it working I don't know why this works. I compared the dockerd binary from both builds, the official snap and my snap. Both are the exact same version, from the exact same commit. If I run strings on both binaries the docker-default template is exactly the same between the two. However, one works with kubelet and the other doesn't. If this ever stops working then I'd suggest trying the above where the docker-snap is built with a modified apparmor policy patch. Maybe somebody else wants to look into this and try to figure out what's special about the official docker snap that makes it fail when our own build works.

### Problem 2: Kubernetes Secret Volumes And Snap
Kubernetes has built-in support for a handful of [volume types](https://kubernetes.io/docs/concepts/storage/volumes/). Volumes can be attached to Pods from various sources after which they become mounted as part of that Pod's filesystem. Two common types of volumes are configMap and secret volumes whereby kubelet maps a ConfigMap or Secret resource stored in the API server to the filesystem of a Pod. The process for doing looks roughly like this:

1. Kubelet receives a new Pod from the API server and starts the setup process for the Pod
1. Kubelet creates a directory for this Pod where it can set up volumes (usually something like /var/lib/kubelet/pods/a02257f2-c68d-11e9-9621-263fe8375b9volumes. If the Pod requires volumes kubelet will create a subdirectory here for each volume attached to the Pod.
1. Kubelet sees that this Pod requires a volume whose type is Secret or ConfigMap
1. Kubelet requests the Secret or ConfigMap from the API server
1. Kubelet sets up files in a directory using the data inside the Secret or ConfigMap and maps that to the Pod's filesystem

Secrets and ConfigMaps are basically just maps consisting of key-value pairs. When they are mounted as volumes each key should map to a file in the target directory inside the Pod. While the way Secrets and ConfigMaps are handled is quite similar there is a subtle difference that causes Secret volumes to break when running kubelet and docker in different snaps. Both types of volumes will be based on a directory inside of that Pod's volumes directory (i.e. /var/lib/kubelet/pods/a02257f2-c68d-11e9-9621-263fe8375b9d/volumes) where each subdirectory is bound to some target path inside the Pod's filesystem. In the case of ConfigMaps, kubelet simply calls Mkdir to set up the subdirectory for that volume and writes files to that subdirectory. In the case of Secrets, kubelet calls Mkdir to set up a subdirectory, creates a tmpfs mount inside that directory then writes files to that subdirectory. Kubelet uses tmpfs for Secrets so that sensitive data such as certificates and keys, which is what Secrets tend to be used for, is not stored unencrypted on disk. For more details you can consult this [code](https://github.com/kubernetes/kubernetes/blob/ad6f30c53571058dd8cf882a046c5b46514e6875/pkg/volume/emptydir/empty_dir.go#L223). ConfigMaps follow the `v1.StorageMediumDefault` branch of this switch statement. Secrets follow the `v1.StorageMediumMemory` branch.

Each snap exists in its own mount namespace as described [here](https://github.com/snapcore/snapd/blob/master/cmd/snap-confine/README.mount_namespace). Any mounts created by the process in a snap are not visible to processes outside of that snap's mount namespace. ConfigMaps work because kubelet doesn't create any new mounts. It creates a directory in an existing mount and writes files to that directory. The directory and its contents are visible outside that snap's mount namespace. Secrets don't work because a new mount is created which isn't visible to processes outside kubelet's snap.

I deployed these resources to test ConfigMap and Secret volumes

* [my-cm.yaml](./volumes/my-cm.yaml)
* [my-secret.yaml](./volumes/my-secret.yaml)
* [test-pod-mounts.yaml](./volumes/test-pod-mounts.yaml)

```bash
barheadedgoose@localhost:~$ df
Filesystem     1K-blocks    Used Available Use% Mounted on
udev              742044       0    742044   0% /dev
tmpfs             149492   30308    119184  21% /run
/dev/sda3        3660620 2241668   1215804  65% /writable
/dev/loop0         90880   90880         0 100% /
/dev/loop1        159744  159744         0 100% /lib/modules
tmpfs             747460       4    747456   1% /etc/fstab
tmpfs             747460      32    747428   1% /dev/shm
tmpfs               5120       0      5120   0% /run/lock
tmpfs             747460       0    747460   0% /sys/fs/cgroup
tmpfs             747460       0    747460   0% /media
tmpfs             747460       0    747460   0% /mnt
tmpfs             747460       0    747460   0% /var/lib/sudo
tmpfs             747460   24320    723140   4% /tmp
/dev/loop2          9216    9216         0 100% /snap/snappy-debug/383
/dev/loop4           896     896         0 100% /snap/pc/33
/dev/loop6         90624   90624         0 100% /snap/core/7270
/dev/loop5        159616  159616         0 100% /snap/pc-kernel/258
/dev/loop7          1024    1024         0 100% /snap/strace-static/18
/dev/loop10       159744  159744         0 100% /snap/pc-kernel/270
/dev/loop8         55808   55808         0 100% /snap/core18/1074
/dev/loop11        90880   90880         0 100% /snap/core/7396
/dev/sda2          50396    2417     47980   5% /boot/efi
cgmfs                100       0       100   0% /run/cgmanager/fs
tmpfs             149492       0    149492   0% /run/user/1000
/dev/loop3         99200   99200         0 100% /snap/docker/x1
/dev/loop9        151296  151296         0 100% /snap/pelion-edge/x1
barheadedgoose@localhost:~$ sudo ls /var/snap/pelion-edge/x1/var/lib/kubelet/pods/a02257f2-c68d-11e9-9621-263fe8375b9d/volumes/kubernetes.io~secret/my-secret
barheadedgoose@localhost:~$ sudo snap run --shell pelion-edge.kubelet
root@localhost:/home/barheadedgoose# df
Filesystem     1K-blocks    Used Available Use% Mounted on
/dev/loop0         90880   90880         0 100% /
/dev/loop1        159744  159744         0 100% /lib/modules
tmpfs             149492   30308    119184  21% /run
tmpfs               5120       0      5120   0% /run/lock
cgmfs                100       0       100   0% /run/cgmanager/fs
tmpfs             149492       0    149492   0% /run/user/1000
/dev/sda3        3660620 2241696   1215776  65% /writable
/dev/loop2          9216    9216         0 100% /snap/snappy-debug/383
/dev/loop4           896     896         0 100% /snap/pc/33
/dev/loop6         90624   90624         0 100% /snap/core/7270
/dev/loop5        159616  159616         0 100% /snap/pc-kernel/258
/dev/loop7          1024    1024         0 100% /snap/strace-static/18
/dev/loop10       159744  159744         0 100% /snap/pc-kernel/270
/dev/loop8         55808   55808         0 100% /snap/core18/1074
/dev/loop11        90880   90880         0 100% /snap/core/7396
/dev/loop3         99200   99200         0 100% /snap/docker/x1
/dev/loop9        151296  151296         0 100% /snap/pelion-edge/x1
tmpfs             747460       4    747456   1% /etc/fstab
tmpfs             747460       0    747460   0% /media
tmpfs             747460       0    747460   0% /mnt
tmpfs             747460       0    747460   0% /var/lib/sudo
tmpfs             747460   24320    723140   4% /tmp
/dev/sda2          50396    2417     47980   5% /boot/efi
udev              742044       0    742044   0% /dev
tmpfs             747460      32    747428   1% /dev/shm
tmpfs             747460       0    747460   0% /sys/fs/cgroup
tmpfs             747460      16    747444   1% /var/lib
tmpfs             747460       4    747456   1% /var/snap/pelion-edge/x1/var/lib/kubelet/pods/a02257f2-c68d-11e9-9621-263fe8375b9d/volumes/kubernetes.io~secret/my-secret
root@localhost:/home/barheadedgoose# ls /var/snap/pelion-edge/x1/var/lib/kubelet/pods/a02257f2-c68d-11e9-9621-263fe8375b9d/volumes/kubernetes.io~secret/my-secret
example.txt
```

Here I show the view of the /var/snap/pelion-edge/x1/var/lib/kubelet/pods/a02257f2-c68d-11e9-9621-263fe8375b9d/volumes/kubernetes.io~secret/my-secret directory from inside the snap's mount namespace and outside to show the results. example.txt is visible inside the pelion-edge snap's mount namespace. It is not visible outside, so is not visible to the docker container. This manifests itself by appearing to be an empty directory inside the container.

The only solution to this problem was to put docker inside the same snap as the other software so everything would operate inside the same mount namespace.

## Integrating Docker Into The Pelion Edge Snap