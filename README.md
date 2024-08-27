# WireGuard

This is a simple image to run a WireGuard client. It includes a kill switch to ensure that any traffic not encrypted via WireGuard is dropped.

THIS IS FORK WITH SOME CHANGED CODE

WireGuard is implemented as a kernel module, which is key to its performance and simplicity. However, this means that WireGuard _must_ be installed on the host operating system for this container to work properly. Instructions for installing WireGuard can be found [here](http://wireguard.com/install).

You will need a configuration file for your WireGuard interface. Many VPN providers will create this configuration file for you. If your VPN provider offers to include a kill switch in the configuration file, be sure to DECLINE, since this container image already has one.

Now simply mount the configuration file and run!

## Docker

```bash
$ docker run --name wireguard                                      \
  --cap-add NET_ADMIN                                              \
  --cap-add SYS_MODULE                                             \
  --sysctl net.ipv4.conf.all.src_valid_mark=1                      \
  -v /path/to/your/config.conf:/etc/wireguard/wg0.conf             \
  jordanpotter/wireguard
```

Afterwards, you can link other containers to this one:

```bash
$ docker run --rm                                                  \
  --net=container:wireguard                                        \
  curlimages/curl ifconfig.io
```

## Docker Compose

Here is the same example as above, but using Docker Compose:

```yml
services:
  wireguard:
    container_name: wireguard
    image: jordanpotter/wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      net.ipv4.conf.all.src_valid_mark: 1
    volumes:
      - /path/to/your/config.conf:/etc/wireguard/wg0.conf
    restart: unless-stopped

  curl:
    image: curlimages/curl
    command: ifconfig.io
    network_mode: service:wireguard
    depends_on:
      - wireguard
```

## Podman

```bash
$ podman run --name wireguard                                      \
  --cap-add NET_ADMIN                                              \
  --cap-add NET_RAW                                                \
  --sysctl net.ipv4.conf.all.src_valid_mark=1                      \
  -v /path/to/your/config.conf:/etc/wireguard/wg0.conf             \
  docker.io/jordanpotter/wireguard
```

Afterwards, you can link other containers to this one:

```bash
$ podman run --rm                                                  \
  --net=container:wireguard                                        \
  docker.io/curlimages/curl ifconfig.io
```

## Local Network

If you wish to allow traffic to your local network, specify the subnet(s) using the `LOCAL_SUBNETS` environment variable:

```bash
$ docker run --name wireguard                                      \
  --cap-add NET_ADMIN                                              \
  --cap-add SYS_MODULE                                             \
  --sysctl net.ipv4.conf.all.src_valid_mark=1                      \
  -v /path/to/your/config.conf:/etc/wireguard/wg0.conf             \
  -e LOCAL_SUBNETS=10.1.0.0/16,10.2.0.0/16,10.3.0.0/16             \
  jordanpotter/wireguard
```

Additionally, you can expose ports to allow your local network to access services linked to the WireGuard container:

```bash
$ docker run --name wireguard                                      \
  --cap-add NET_ADMIN                                              \
  --cap-add SYS_MODULE                                             \
  --sysctl net.ipv4.conf.all.src_valid_mark=1                      \
  -v /path/to/your/config.conf:/etc/wireguard/wg0.conf             \
  -p 8080:80                                                       \
  jordanpotter/wireguard
```

```bash
$ docker run --rm                                                  \
  --net=container:wireguard                                        \
  nginx
```

## Versioning

This container image is rebuilt weekly with the latest security updates. Each build runs tests to verify all features continue to work as expected, including the kill switch and local network routing.

Images are tagged with the date of the build in `YYYY-MM-DD` format. The available image tags are listed [here](https://hub.docker.com/r/jordanpotter/wireguard/tags).
