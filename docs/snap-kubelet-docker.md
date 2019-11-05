# Snap, kubelet and Docker

Kubelet uses a ["container runtime"](https://kubernetes.io/docs/setup/production-environment/container-runtimes/) to manage containers for Pods.

Docker is one of the most common container runtimes and is paired with kubelet in this build. We encountered several obstacles while integrating kubelet, Docker and snap. This document outlines the process we went through to arrive at our current setup, including the problems and their solutions at each step.

## Using the official Docker snap

Before knowing the restrictions the snap environment enforced, we considered the tradeoffs between packaging Docker inside our snap and using the off-the-shelf Docker snap. We considered that packaging Docker with our snap might have undesirable side-effects if a user were to install our snap on a system where Docker was already installed. After all, our snap may not be the only user of Docker on that system, and we didn't want to require users with Docker already running to uninstall their Docker daemons and use ours instead. It was unclear how running two instances of Docker on a system would affect it and what kind of isolation snaps provided. We decided to integrate with an off-the-shelf Docker snap and keep our software in a different snap. This was appealing because we avoided possible conflicts with other Docker daemons, made our build process easier and made our snap smaller. The task seemed simple enough, but quirks of snap and the isolation it provides precludes this approach.

### Problem 1: AppArmor profiles and ptrace

When kubelet starts, it talks to a Kubernetes API server in the cloud to discover which Pods it has been assigned. A Pod is a specification for a set of containers that share the same networking namespace and the parameters you should run them with. After kubelet receives a Pod assignment from the API server, it asks Docker to start a [pause container](https://www.ianlewis.org/en/almighty-pause-container) for this Pod that it uses to initialize the Pod's networking namespace that all other containers belong to. All containers in a Pod therefore share an IP address and can talk to one another over localhost.

Container networking interface (CNI) plugins are responsible for initializing the networking interfaces for a Pod when it starts. CNI plugins are just executables kubelet starts when it wants to configure the network interfaces of a new Pod. The loopback CNI plugin sets up the loopback interface for a Pod. When trying to run the pelion-edge snap alongside the official Docker snap, the kubelet logs showed these errors while trying to deploy a Pod:

```
Aug 21 18:37:24 localhost.localdomain pelion-edge.kubelet[10990]: E0821 18:37:24.426195   10990 cni.go:309] Error adding default_test-pod-016c6de7e4f7000000000001001003c1/2017642be9f6094dec4997f658cc4187ade60eb193fa1b8ef1f064b988502412 to network loopback/cni-loopback: failed to Statfs "/proc/14361/ns/net": permission denied
...
Aug 21 18:37:24 localhost.localdomain pelion-edge.kubelet[10990]: E0821 18:37:24.896277   10990 remote_runtime.go:96] RunPodSandbox from runtime service failed: rpc error: code = Unknown desc = failed to set up sandbox container "2017642be9f6094dec4997f658cc4187ade60eb193fa1b8ef1f064b988502412" network for pod "test-pod-016c6de7e4f7000000000001001003c1": NetworkPlugin cni failed to set up pod "test-pod-016c6de7e4f7000000000001001003c1_default" network: failed to Statfs "/proc/14361/ns/net": permission denied
Aug 21 18:37:24 localhost.localdomain pelion-edge.kubelet[10990]: E0821 18:37:24.896367   10990 kuberuntime_sandbox.go:65] CreatePodSandbox for pod "test-pod-016c6de7e4f7000000000001001003c1_default(2032456b-c2b8-11e9-9621-263fe8375b9d)" failed: rpc error: code = Unknown desc = failed to set up sandbox container "2017642be9f6094dec4997f658cc4187ade60eb193fa1b8ef1f064b988502412" network for pod "test-pod-016c6de7e4f7000000000001001003c1": NetworkPlugin cni failed to set up pod "test-pod-016c6de7e4f7000000000001001003c1_default" network: failed to Statfs "/proc/14361/ns/net": permission denied
Aug 21 18:37:24 localhost.localdomain pelion-edge.kubelet[10990]: E0821 18:37:24.896412   10990 kuberuntime_manager.go:662] createPodSandbox for pod "test-pod-016c6de7e4f7000000000001001003c1_default(2032456b-c2b8-11e9-9621-263fe8375b9d)" failed: rpc error: code = Unknown desc = failed to set up sandbox container "2017642be9f6094dec4997f658cc4187ade60eb193fa1b8ef1f064b988502412" network for pod "test-pod-016c6de7e4f7000000000001001003c1": NetworkPlugin cni failed to set up pod "test-pod-016c6de7e4f7000000000001001003c1_default" network: failed to Statfs "/proc/14361/ns/net": permission denied
Aug 21 18:37:24 localhost.localdomain pelion-edge.kubelet[10990]: E0821 18:37:24.896516   10990 pod_workers.go:190] Error syncing pod 2032456b-c2b8-11e9-9621-263fe8375b9d ("test-pod-016c6de7e4f7000000000001001003c1_default(2032456b-c2b8-11e9-9621-263fe8375b9d)"), skipping: failed to "CreatePodSandbox" for "test-pod-016c6de7e4f7000000000001001003c1_default(2032456b-c2b8-11e9-9621-263fe8375b9d)" with CreatePodSandboxError: "CreatePodSandbox for pod \"test-pod-016c6de7e4f7000000000001001003c1_default(2032456b-c2b8-11e9-9621-263fe8375b9d)\" failed: rpc error: code = Unknown desc = failed to set up sandbox container \"2017642be9f6094dec4997f658cc4187ade60eb193fa1b8ef1f064b988502412\" network for pod \"test-pod-016c6de7e4f7000000000001001003c1\": NetworkPlugin cni failed to set up pod \"test-pod-016c6de7e4f7000000000001001003c1_default\" network: failed to Statfs \"/proc/14361/ns/net\": permission denied"
```

These logs show the same error bubbling up through the stack, but the core issue is reported in the first line:

```
Aug 21 18:37:24 localhost.localdomain pelion-edge.kubelet[10990]: E0821 18:37:24.426195   10990 cni.go:309] Error adding default_test-pod-016c6de7e4f7000000000001001003c1/2017642be9f6094dec4997f658cc4187ade60eb193fa1b8ef1f064b988502412 to network loopback/cni-loopback: failed to Statfs "/proc/14361/ns/net": permission denied
```

After investigating, we found this error is generated in the [github.com/containernetworking/plugins/package/ns](https://github.com/containernetworking/plugins/blob/485be65581341430f9106a194a98f0f2412245fb/pkg/ns/ns_linux.go#L122) package, a dependency of the loopback CNI binary where it makes a Statfs system call to /proc/14361/ns/net, where 14361 is the PID of the pause container process for the new Pod. Ultimately, the Pod creation fails, and kubelet tears everything down. The Pod remains in the ContainerCreating state in the API server as kubelet tries and fails repeatedly. This error occurs whether the pelion-edge snap is running with devmode or strict isolation.

We weren't sure what was causing these permission errors. We used the snappy-debug tool to see if AppArmor is denying any system calls and to get some more information about why they are rejected:

```bash
barheadedgoose@localhost:~$ sudo snappy-debug.security scanlog | grep DENIED
INFO: Detected Ubuntu Core. For best results, redirect journalctl. Eg:
INFO: $ sudo journalctl --output=short --follow --all | sudo snappy-debug
WARN: could not find log mark, is syslog enabled?
Log: AppArmor="DENIED" operation="ptrace" profile="docker-default" pid=1666 comm="loopback" requested_mask="tracedby" denied_mask="tracedby" peer="snap.pelion-edge.kubelet"
Log: AppArmor="DENIED" operation="ptrace" profile="docker-default" pid=1824 comm="loopback" requested_mask="tracedby" denied_mask="tracedby" peer="snap.pelion-edge.kubelet"
Log: AppArmor="DENIED" operation="ptrace" profile="docker-default" pid=1977 comm="loopback" requested_mask="tracedby" denied_mask="tracedby" peer="snap.pelion-edge.kubelet"
Log: AppArmor="DENIED" operation="ptrace" profile="docker-default" pid=2139 comm="loopback" requested_mask="tracedby" denied_mask="tracedby" peer="snap.pelion-edge.kubelet"
Log: AppArmor="DENIED" operation="ptrace" profile="docker-default" pid=2285 comm="loopback" requested_mask="tracedby" denied_mask="tracedby" peer="snap.pelion-edge.kubelet"
```

There seemed to be a correlation between these AppArmor the "permission denied" errors seen in the kubelet logs. If the two were connected, that would imply this `docker-default` AppArmor policy was responsible for the "permission denied" errors occuring in the loopback CNI plugin. The missing link here was the PID of the loopback CNI plugin process. The kubelet logs told us the PID of the container process, but the snappy-debug logs contained PIDs from unknown processes. We strongly suspected these were the PIDs of the loopback CNI plugin processes but were unable to confirm this because the loopback CNI plugin executed too fast for inspection to work with `ps`.

We ran kubelet with strace, so we could see the PIDs of all the child processes it creates. This would allow us to match the PID contained in the snappy-debug logs with the PIDs of the loopback CNI processes.

1. We stopped the kubelet service, so we could run it in the foreground with strace:
   
   ```bash
   barheadedgoose@localhost:~$ sudo service snap.pelion-edge.kubelet stop
   ```
   
2. We started the snap in the foreground with strace enabled:
   
   ```bash
   barheadedgoose@localhost:~$ sudo snap run --strace="-f -o kubelet.strace.out" pelion-edge.kubelet
   ```
   
   A new file was created for each child process with a log of the system calls it makes.

3. We crossreferenced a few of the PIDs listed in the snappy-debug log with the the strace output for kubelet child processes with a matching PID:
   
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

Based on the system calls contained in these files, the AppArmor DENIED errors were the direct cause of the statfs "permission denied" errors. Now the question became "What is this `docker-default` AppArmor policy, and why is it blocking these system calls?".

#### `docker-default` Policy

Snap creates AppArmor policies for snaps based on the snap's plug and slot settings. AppArmor policies for devmode snaps are put into complain mode where profile violations are reported but not enforced. Snap sets the AppArmor profile for strict snaps to enforce mode where the profile is enforced. After a little research, [we found](https://docs.docker.com/engine/security/apparmor/) the `docker-default` policy is applied to container processes by Docker, not something generated by snap. However, if this were the case, why did this problem only present itself when running Docker inside a snap?

It turns out the [docker-snap](https://code.launchpad.net/~docker/+git/snap) build process actually patches Dockerd's code to edit the template used to generate the `docker-default` AppArmor profile:

```
+ # Snap based docker distribution accesses
+ # Allow the daemon to trace/signal containers
+ ptrace (readby, tracedby) peer="snap.docker.dockerd",
+ signal (receive) peer="snap.docker.dockerd",
+ # Allow container processes to signal other container processes
+ signal (send, receive) peer=docker-default,
```

The policy would only allow ptrace system calls from the `snap.docker.dockerd` process, the Docker daemon inside the Docker snap. As we discovered later, these rules only seem to apply between two processes that both have AppArmor profiles applied. If we performed this system call from a process that was not running in the snap environment, and therefore did not have an AppArmor profile applied, there were no permission problems.

A simple fix seemed to be to edit this patch so that snap.pelion-edge.kubelet is added as a ptrace peer. To test this, we needed to build the Docker snap ourselves from source:

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

As a control, we started by building the Docker snap from this repository: [https://git.launchpad.net/~docker/+git/snap/](https://git.launchpad.net/~docker/+git/snap/) without making any modifications. It was hard to determine which commit they built the latest official snap from, but we just built from the latest commit on master where the Docker version matched what was installed by the official snap. We needed to verify this problem is repeatable even when we build the snap ourselves. We verified the `docker-default` AppArmor profile patch was the same in the commit we were building from. We built the snap, uninstalled the official Docker snap from our gateway, then installed our Docker snap build. It worked.

The snap we built from the unmodified Docker-snap repository worked without any permissions problems. We stopped here, having found a configuration that got around the AppArmor permission problems. This workaround was messy. Our initial intent was to simplify the deployment by using the official Docker snap, but now we had to deliver a custom Docker snap with the pelion-edge snap. This was hardly better than just integrating Docker into the pelion-edge snap. As we later found, putting Docker into the pelion-edge snap was unavoidable. There were certain problems that could not be avoided unless we merged them together.

### Problem 2: Kubernetes secret volumes and snap

Kubernetes has built-in support for a handful of [volume types](https://kubernetes.io/docs/concepts/storage/volumes/). Volumes can be attached to Pods from various sources after which they become mounted as part of that Pod's file system. Two common types of volumes are configMap and secret volumes, whereby kubelet maps a ConfigMap or Secret resource stored in the API server to the filesystem of a Pod. The process for doing so looks roughly like this:

1. Kubelet receives a new Pod from the API server and starts the setup process for the Pod.
1. Kubelet creates a directory for this Pod where it can set up volumes (usually something like /var/lib/kubelet/pods/a02257f2-c68d-11e9-9621-263fe8375b9volumes. If the Pod requires volumes kubelet will create a subdirectory here for each volume attached to the Pod.
1. Kubelet sees that this Pod requires a volume whose type is Secret or ConfigMap.
1. Kubelet requests the Secret or ConfigMap from the API server.
1. Kubelet sets up files in a directory using the data inside the Secret or ConfigMap and maps that to the Pod's file system.

Secrets and ConfigMaps are basically just maps consisting of key-value pairs. When they are mounted as volumes, each key should map to a file in the target directory inside the Pod. Although the way Secrets and ConfigMaps are handled is similar, there is a subtle difference that causes Secret volumes to break when running kubelet and Docker in different snaps. Both types of volumes are based on a directory inside of that Pod's volumes directory (in other words, /var/lib/kubelet/pods/a02257f2-c68d-11e9-9621-263fe8375b9d/volumes) where each subdirectory is bound to some target path inside the Pod's file system. In the case of ConfigMaps, kubelet simply calls Mkdir to set up the subdirectory for that volume and writes files to that subdirectory. In the case of Secrets, kubelet calls Mkdir to set up a subdirectory, creates a tmpfs mount inside that directory then writes files to that subdirectory. Kubelet uses tmpfs for Secrets, so sensitive data such as certificates and keys, which is what Secrets tend to be used for, is not stored unencrypted on disk. For more details, you can consult this [code](https://github.com/kubernetes/kubernetes/blob/ad6f30c53571058dd8cf882a046c5b46514e6875/pkg/volume/emptydir/empty_dir.go#L223). ConfigMaps follow the `v1.StorageMediumDefault` branch of this switch statement. Secrets follow the `v1.StorageMediumMemory` branch.

Each snap [exists in its own mount namespace](https://github.com/snapcore/snapd/blob/master/cmd/snap-confine/README.mount_namespace). Any mounts created by the process in a snap are not visible to processes outside of that snap's mount namespace. ConfigMaps work because kubelet doesn't create any new mounts. It creates a directory in an existing mount and writes files to that directory. The directory and its contents are visible outside that snap's mount namespace. Secrets don't work because a new mount is created, which isn't visible to processes outside kubelet's snap.

We deployed these resources to test ConfigMap and Secret volumes:

* [my-cm.yaml](./volumes/my-cm.yaml).
* [my-secret.yaml](./volumes/my-secret.yaml).
* [test-pod-mounts.yaml](./volumes/test-pod-mounts.yaml).

We first noticed a problem when a Pod that mounted a Secret and a ConfigMap could see files mounted from the ConfigMap but not the Secret. In effect, the volume mapped to a Secret appeared to be empty to container processes while the volume mapped to the ConfigMap contained the expected files. Because Docker containers exist within the Docker snap's mount namespace but the tmpfs mount was created by kubelet inside the pelion-edge snap's mount namespace, the mount, and hence the file, was not visible to the Docker container inside the Pod. We didn't need to do anything special to verify this. We just run `df` from a normal shell, which runs in a different mount namespace than the kubelet process, and see that the tmpfs mount is not visible:

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
```

Next, we run a shell inside the same mount namespace as kubelet and the tmpfs mount is visible along with the files:

```bash
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

Other than changing how snap itself works, the only solution to this problem was to put Docker inside the same snap as the other software, so everything would operate inside the same mount namespace.

## Integrating Docker into the Pelion Edge snap

As we found in the last section, certain problems were unavoidable if we didn't put Docker inside the same snap as kubelet, notably the problem with secret volume mounts. Integrating Docker into the pelion-edge snap was relatively straightforward; we just needed to merge elements from the Docker-snap snapcraft file into the pelion-edge snapcraft file.

### Modifying the `docker-default` policy

One non-obvious change we had to make to integrate Docker into our snap was the modification of the `docker-default` policy patch. We needed to change `snap.docker.dockerd` to `snap.pelion-edge.dockerd` to avoid ptrace AppArmor permission problems as described above:

```
diff --git a/components/engine/profiles/apparmor/template.go b/components/engine/profiles/apparmor/template.go
index c00a3f70e9..1d8f66c823 100644
--- a/components/engine/profiles/apparmor/template.go
+++ b/components/engine/profiles/apparmor/template.go
@@ -40,5 +40,12 @@ profile {{.Name}} flags=(attach_disconnected,mediate_deleted) {
   # suppress ptrace denials when using 'docker ps' or using 'ps' inside a container
   ptrace (trace,read) peer={{.Name}},
 {{end}}
+
+  # Snap based docker distribution accesses
+  #   Allow the daemon to trace/signal containers
+  ptrace (readby, tracedby) peer="snap.pelion-edge.dockerd",
+  signal (receive) peer="snap.pelion-edge.dockerd",
+  #   Allow container processes to signal other container processes
+  signal (send, receive) peer=docker-default,
 }
 `
```
