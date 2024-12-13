# docker-homelab :house: :test_tube:
This repository contains my automated homelab setup and configurations. 

**README documentation is in progress**

## Features
| Name | Service | Description | Type | Ports | Links |
| ---  | ---     | ---         | ---  | ---   | ---   |
| Secrets/ Configurations | Doppler | Doppler provides a platform for secrets and app configuration management. Doppler supports secrets management in docker and docker and docker compose, making it an easy choice for use in my homelab. This allows me to maintain all production ready configurations and docker compose files without the risk of exposing private or secrets information to my public repository. (no .env files required) | External | N/A | [Doppler](https://www.doppler.com/) |
| CDN/ Security | Cloudflare | Cloudflare provides various securities for websites including protection from DDoS attacks, malicious bots, and other intrusions. | External | N/A | [Cloudflare](https://www.cloudflare.com/) |
| Reverse Proxy | Traefik | Traefik is an open source reverse proxy and load balancer that specializes in microservices deployments. | Internal | 80 443 8080  | [Traefik](https://traefik.io/) |


## Info

## Setup
