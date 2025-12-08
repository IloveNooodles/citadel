# Patch

## Mounting longhorn volumes

```sh
talosctl patch machineconfig -p longhorn.yaml -n 192.168.1.113,192.168.1.140
```

## Cillium Patch

```sh
talosctl --talosconfig talosconfig patch machineconfig -p @../talos/cillium.yaml -n 192.168.1.57,192.168.1.133
```
