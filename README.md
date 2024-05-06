# Transparent proxy for Docker containers

Traefik image pre-configured to act as a transparent proxy. It allows containers without direct Internet access to connect to specific domains.

```yaml
services:

  yourapp:
    image: "registry.example.com/yourapp:latest"
    networks:
      private:

  proxy:
    image: "docker.io/hectorm/proxy:v2"
    networks:
      public:
      private:
        aliases:
          - "example.com"
          - "smtp.example.com"
          - "postgres.example.com"
    environment:
      PROXY_UPSTREAMS: |
        example.com:443
        smtp.example.com:465
        smtp.example.com:587:catchall
        postgres.example.com:5432

networks:

  public:
    internal: false

  private:
    internal: true
```
