# Wireguard
This is a simple docker image to run a Wireguard client. It includes a kill switch to ensure that any traffic not encrypted via Wireguard is dropped.

Wireguard is implemented as a kernel module, which is key to its performance and simplicity. However, this means that Wireguard _must_ be installed on the host operating system for this container to work properly. Instructions for installing Wireguard can be found [here](http://wireguard.com/install).

You will need a configuration file for your Wireguard interface. Many VPN providers will create this configuration file for you. For example, [here](http://mullvad.net/en/download/wireguard-config) is the configuration generator for Mullvad. Be sure to NOT include a kill switch in the configuration file, since the docker image already has one.

Now simply mount the configuration file and run! For example, if your configuration file is located at `/path/to/conf/mullvad.conf`:

```bash
docker run --name wireguard                                          \
    --cap-add NET_ADMIN                                              \
    --cap-add SYS_MODULE                                             \
    --sysctl net.ipv4.conf.all.src_valid_mark=1                      \
    -v /path/to/conf/mullvad.conf:/etc/wireguard/mullvad.conf        \
    jordanpotter/wireguard
```

Afterwards, you can link other containers to this one:

```bash
docker run -it --rm                                                  \
    --net=container:wireguard                                        \
    appropriate/curl http://httpbin.org/ip
```

Wireguard is new technology and its behavior may change in the future. For this reason, it's recommended to specify an image tag when running this container, such as `jordanpotter/wireguard:1.0.0`. The available tags are listed [here](https://hub.docker.com/r/jordanpotter/wireguard/tags).
