# Offline Mode for Kubelet

The Kubelet version contained in this snap has support for _offline mode_.  Running Kubelet in offline mode tells it to start pods that it knows about, even if it can't reach the Internet.  Offline mode is enabled by default.

To disable offline mode for Kubelet, type this:
```
snap set pelion-edge kubelet.offline-mode=false
```

To enable offline mode again, type this:
```
snap set pelion-edge kubelet.offline-mode=true
```
