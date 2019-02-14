# Wireguard
This is a simple docker image to run a wireguard client.

Wireguard is implemented as a kernel module, which is key to its performance and simplicity. However, this means that Wireguard _must_ be installed on the host operating system for this container to work properly. Instructions for installing Wireguard can be found [here](http://wireguard.com/install).

You will need a configuration file for your Wireguard interface. Many VPN providers will create this configuration file for you. For example, [here](http://mullvad.net/en/download/wireguard-config) is the configuration generator for Mullvad.

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
