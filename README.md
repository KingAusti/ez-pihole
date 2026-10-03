# ez-pihole

[![CI](https://github.com/KingAusti/ez-pihole/actions/workflows/ci.yml/badge.svg)](https://github.com/KingAusti/ez-pihole/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Shell scripts and a Docker Compose file for running [Pi-hole](https://pi-hole.net/)
in a container on a Mac. It is meant for a home setup where one Mac, such as a
Mac mini, stays on and serves DNS to the rest of the network. It targets macOS
with Docker Desktop and has not been written or tested for Linux or Windows.

## Requirements

- macOS with [Docker Desktop](https://www.docker.com/products/docker-desktop/)
  installed and running
- A Mac with a stable LAN address (a DHCP reservation on the router works)
- Free ports 53, 80 and 443, or willingness to let `resolve-ports.sh` pick others

## Quick start

1. Clone the repository and enter it. All scripts expect to run from this directory.

   ```sh
   git clone https://github.com/KingAusti/ez-pihole.git
   cd ez-pihole
   ```

2. Run the launcher.

   ```sh
   ./start-pihole.sh
   ```

   If `.env` or the `etc-pihole` directory is missing, it offers to run
   `first-time-setup.sh`. Accept.

3. Answer the wizard. It checks Docker, detects the Mac's IP, resolves port
   conflicts, asks for a web password (default `change-me`, so set your own), a
   timezone and an upstream DNS choice, writes `.env`, creates `etc-pihole` and
   `etc-dnsmasq.d`, and runs `docker compose up -d`.

4. Open the admin page at `http://192.168.1.10/admin`, using the IP the wizard
   detected. If a port was changed, add `:<HTTP_PORT>` after the IP.

5. Point your router, or individual devices, at the Mac's IP for DNS.
   `./network-setup.sh` prints per-device and router instructions and can test
   resolution.

On later runs, `./start-pihole.sh` shows a menu if the container is running.

## Configuration

`.env` is git-ignored. `first-time-setup.sh` writes it, or `setup.sh` copies
`.env.example`. Not every key reaches the container. `docker-compose.yml` only
substitutes two of them and hard-codes the rest.

| Key | Example | Used by |
| --- | --- | --- |
| `SERVER_IP` | `192.168.1.10` | Compose (`ServerIP`, `FTLCONF_LOCAL_IPV4`); also read by the scripts to build URLs |
| `PIHOLE_PASSWORD` | `change-me` | Compose, passed to the container as `WEBPASSWORD` |
| `TZ` | `America/New_York` | Written by the wizard only. Compose hard-codes `America/New_York` |
| `DNS1`, `DNS2` | `1.1.1.1`, `1.0.0.1` | Written by the wizard only. Compose hard-codes Cloudflare |
| `DNS_PORT` | `53` | Scripts only (`pihole-manager.sh`, `validate-setup.sh`) |
| `HTTP_PORT` | `80` | Scripts only (launcher, manager) to build the admin URL |
| `HTTPS_PORT` | `443` | Scripts only (`pihole-manager.sh`) |

The published ports and the timezone and upstream DNS servers are set in
`docker-compose.yml`. To change timezone or upstream DNS, edit that file.
`resolve-ports.sh` rewrites the `ports` section of it, and the wizard does the
same when it finds a conflict. After editing `.env` or the compose file, apply
the change with `docker compose up -d`.

## Scripts

Run everything from the repository root.

| Script | Purpose |
| --- | --- |
| `start-pihole.sh` | Entry point. Starts the wizard on first run, otherwise a menu (admin page, status, manager, network help, stop) |
| `first-time-setup.sh` | Setup wizard described in Quick start. Sources `resolve-ports.sh` |
| `pihole-manager.sh` | Menu to start, stop, restart, view logs and stats, update, edit `.env`, test, and resolve ports |
| `status.sh` | Prints container status, web and DNS checks and basic stats. `-m` or `--monitor` keeps refreshing |
| `network-setup.sh` | Menu with router and device DNS instructions, a macOS DNS helper and connectivity tests |
| `resolve-ports.sh` | Finds free ports when 53, 80 or 443 are taken. Rewrites `docker-compose.yml` and the port keys in `.env` |
| `validate-setup.sh` | Static checks (`.env` keys, compose file, directories, script permissions). Does not need Docker running |
| `test.sh` | Checks that Docker is running, runs `docker compose config`, and checks whether ports 53, 80 and 443 are free |
| `setup.sh` | Older non-interactive path: writes the detected IP to `.env`, creates directories and starts the container. No port handling |
| `version.sh` | Shows the version from `VERSION` and the changelog, and `update <version>` edits version strings |
| `version-check.sh` | Helper functions for reading `VERSION`. No other script uses it |

## Troubleshooting

**Port 53, 80 or 443 is already in use.** Run `./resolve-ports.sh`, or option 12
in `./pihole-manager.sh`. It picks free ports, saves the original compose file
as `docker-compose.yml.backup`, rewrites `docker-compose.yml` and updates the
port keys in `.env`. Restart with `docker compose up -d`. A non-standard DNS
port does not work for ordinary clients, which expect 53, so free port 53 if you
can.

**`validate-setup.sh` reports missing ports after resolving conflicts.** It
looks for the literal standard port mappings in `docker-compose.yml`, so it
flags a compose file that `resolve-ports.sh` has changed.

**Checking what is running.** `./status.sh` shows status, and
`./pihole-manager.sh` has a Troubleshooting entry and a logs entry.

## License

MIT. See [LICENSE](LICENSE).
