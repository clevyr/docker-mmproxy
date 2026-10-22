# go-mmproxy Container

[![Build](https://github.com/clevyr/docker-mmproxy/actions/workflows/build.yaml/badge.svg)](https://github.com/clevyr/docker-mmproxy/actions/workflows/build.yaml)

This repo builds container images for [go-mmproxy](https://github.com/path-network/go-mmproxy), which accepts PROXY protocol connections and forwards them to a backend using the original client IP as the source address. This lets services without PROXY protocol support (like OpenSSH) see real client IPs behind a load balancer.

go-mmproxy hasn't had a release since 2021, so images are built from the upstream `master` branch. The pinned commit is automatically updated by Renovate bot.

## Images

- [ghcr.io/clevyr/docker-mmproxy](https://github.com/clevyr/docker-mmproxy/pkgs/container/docker-mmproxy)

## Deployment

go-mmproxy needs `CAP_NET_ADMIN` to set `IP_TRANSPARENT`, so the image runs as root. It must share a network namespace with the backend, and the namespace needs routing rules so replies to spoofed client IPs are delivered back over loopback:

```sh
ip rule add from 127.0.0.1/8 iif lo table 123
ip route add local 0.0.0.0/0 dev lo table 123
```

### Kubernetes

Run go-mmproxy as a [native sidecar](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/) after an init container that adds the routing rules:

```yaml
initContainers:
  - name: routes
    image: alpine
    command: [sh, -ec]
    args:
      - |
        ip rule add from 127.0.0.1/8 iif lo table 123
        ip route add local 0.0.0.0/0 dev lo table 123
    securityContext:
      capabilities:
        add: [NET_ADMIN]
  - name: mmproxy
    image: ghcr.io/clevyr/docker-mmproxy
    restartPolicy: Always
    args: [-l, 0.0.0.0:2222, -4, 127.0.0.1:22]
    securityContext:
      capabilities:
        add: [NET_ADMIN]
```

The backend should listen on `127.0.0.1` only so connections can't bypass the proxy.
