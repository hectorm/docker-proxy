# Transparent proxy for Docker containers

Traefik image pre-configured to act as a transparent proxy. It allows containers without direct Internet access to connect to specific domains.

```yaml
services:

  yourapp:
    image: "registry.example.com/yourapp:latest"
    networks:
      private:

  proxy:
    image: "docker.io/hectorm/proxy:v1"
    networks:
      public:
      private:
        aliases:
          - "example.com"
          - "example.net"
          - "smtp.example.com"
    environment:
      PROXY_UPSTREAMS_HTTPS: |
        example.com
        example.net
      PROXY_UPSTREAMS_SMTPS: |
        smtp.example.com

networks:

  public:
    internal: false

  private:
    internal: true
```
