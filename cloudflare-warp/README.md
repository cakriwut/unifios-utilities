# cloudflare-warp

## Features

Cloudflare WARP Connector provides a bi-directional tunnel using `warp-cli` as the main tool. This allows you to connect your UDM to Cloudflare Zero Trust network using the WARP connector.

## Requirements

1. You have successfully setup the on boot script described [here](https://github.com/unifi-utilities/unifios-utilities/tree/main/on-boot-script)
2. A Cloudflare Zero Trust account with WARP connector configured
3. A connector token from Cloudflare Zero Trust

## Getting a Connector Token

1. Log in to your [Cloudflare Zero Trust dashboard](https://one.dash.cloudflare.com/)
2. Navigate to **Networks** > **Tunnels**
3. Create a new WARP Connector
4. Copy the connector token that is generated

## Installation

1. Copy `on_boot.d/51-cloudflare-warp-connector.sh` to `/mnt/data/on_boot.d/51-cloudflare-warp-connector.sh`
2. Make the script executable:
   ```bash
   chmod +x /mnt/data/on_boot.d/51-cloudflare-warp-connector.sh
   ```

## Configuration

### WARP Connector

Configuration is required here, otherwise nothing will work.

You need to modify `CONNECTOR_TOKEN` in `51-cloudflare-warp-connector.sh` with the connector token you got from Cloudflare Zero Trust.

```bash
CONNECTOR_TOKEN="YOUR_CONNECTOR_TOKEN_GOES_HERE"
```

Run the script and ensure it doesn't error:

```bash
root@UDM-SE:/mnt/data/on_boot.d# ./51-cloudflare-warp-connector.sh
```

The script will:
1. Set up the Cloudflare WARP repository and GPG key
2. Install or upgrade the `cloudflare-warp` package
3. Enable IP forwarding (`sysctl -w net.ipv4.ip_forward=1`)
4. Start the `warp-svc` daemon service
5. Register the connector with your token
6. Connect to Cloudflare WARP

## Verification

Now check that the services are healthy:

```bash
root@UDM-SE:~# systemctl status warp-svc.service
● warp-svc.service - Cloudflare WARP Service
     Loaded: loaded (/lib/systemd/system/warp-svc.service; enabled; vendor preset: enabled)
     Active: active (running) since ...
   Main PID: xxxx (warp-svc)
      Tasks: xx
     Memory: xx.xM
        CPU: x.xxxs
     CGroup: /system.slice/warp-svc.service
             └─xxxx /usr/bin/warp-svc
```

Check the WARP connector status:

```bash
root@UDM-SE:~# warp-cli status
Status update: Connected
```

You can also check the connector settings:

```bash
root@UDM-SE:~# warp-cli settings
```

## Manual Configuration

If you prefer to configure the connector manually after installation, you can:

1. Run the script without setting the `CONNECTOR_TOKEN` (it will install the package and start the service)
2. Manually register the connector:
   ```bash
   warp-cli connector new YOUR_CONNECTOR_TOKEN
   ```
3. Connect to WARP:
   ```bash
   warp-cli connect
   ```

## Troubleshooting

### Check if IP forwarding is enabled

```bash
sysctl net.ipv4.ip_forward
```

Should return `net.ipv4.ip_forward = 1`

### Check warp-cli logs

```bash
journalctl -u warp-svc.service -f
```

### Disconnect and reconnect

```bash
warp-cli disconnect
warp-cli connect
```

### Check connector registration

```bash
warp-cli connector show
```

## Additional Commands

- `warp-cli status` - Check connection status
- `warp-cli settings` - View current settings
- `warp-cli connect` - Connect to WARP
- `warp-cli disconnect` - Disconnect from WARP
- `warp-cli connector show` - Show connector information
- `warp-cli help` - Show all available commands

## Differences from cloudflared

Unlike `cloudflared` which is primarily used for tunneling specific services or as a DNS-over-HTTPS proxy, the WARP connector:

1. Provides bi-directional network connectivity
2. Routes traffic through Cloudflare's WARP network
3. Integrates with Cloudflare Zero Trust for network-level security policies
4. Requires a connector token instead of a tunnel token
5. Uses `warp-cli` command-line tool instead of `cloudflared`

## References

- [Cloudflare WARP Connector Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/private-net/warp-connector/)
- [Cloudflare Zero Trust](https://www.cloudflare.com/zero-trust/)
