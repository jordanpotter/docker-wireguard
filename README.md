# Wireguard
This is a simple docker image to run a wireguard client. It includes a killswitch to ensure that any traffic not encrypted via wireguard is dropped.

Wireguard is implemented as a kernel module, which is key to its performance and simplicity. However, this means that Wireguard _must_ be installed on the host operating system for this container to work properly. Instructions for installing Wireguard can be found [here](http://wireguard.com/install).

You will need a configuration file for your Wireguard interface. Many VPN providers will create this configuration file for you. For example, [here](http://mullvad.net/en/download/wireguard-config) is the configuration generator for Mullvad. Be sure to NOT include a killswitch in the configuration file, since the docker image already has one.

Now simply mount the configuration file and run! For example, if your configuration file is located at `/path/to/conf/mullvadus2.conf`:

```bash
docker run --name wireguard                                          \
    --cap-add=NET_ADMIN                                              \
    -v /path/to/conf/mullvadus2.conf:/etc/wireguard/mullvadus2.conf  \
    jordanpotter/wireguard
```

Afterwards, you can link other containers to this one:

```bash
docker run -it --rm                                                  \
    --net=container:wireguard                                        \
    appropriate/curl http://httpbin.org/ip
```

## Troubleshooting

### Asymmetric Routing

If you see any errors similar to:

```bash
sysctl: setting key "net.ipv4.conf.all.rp_filter": Read-only file system
sysctl: setting key "net.ipv4.conf.default.rp_filter": Read-only file system
```

Then your host is set to discard packets when the route for outbound traffic differs from the route for incoming traffic. To correct this, you'll want to set these values in `/etc/sysctl.conf`:

```bash
net.ipv4.conf.default.rp_filter = 2
net.ipv4.conf.all.rp_filter = 2
```

Afterwards, reboot.
