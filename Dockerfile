# syntax=docker.io/docker/dockerfile:1

FROM docker.io/traefik:2.10.5@sha256:948978f7ec62f137a79f8af7044a1785bd7868706ef2c8cba9c88db688d08661

COPY ./config/traefik/ /etc/traefik/
COPY ./entrypoint.sh /entrypoint.sh

ENV RESOLVCONF_PATH=/etc/resolv.conf
ENV RESOLVCONF_NAMESERVER_1=1.0.0.1
ENV RESOLVCONF_NAMESERVER_2=1.1.1.1

HEALTHCHECK --start-period=30s --interval=10s --timeout=5s --retries=1 CMD ["traefik", "healthcheck"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["traefik"]

RUN set -eu \
	&& apk add --no-cache curl \
	&& { printf '%s\n' '========== START OF TEST RUN =========='; set -x; } \
	&& { PROXY_UPSTREAMS_HTTPS=docker.com,github.com /entrypoint.sh traefik & } \
	&& timeout 120 sh -euc 'sleep 1; until traefik healthcheck; do sleep 1; done' \
	&& [ "$(curl -IL -sSo /dev/stderr -w '%{http_code}' --connect-to docker.com:443:127.0.0.1:443 https://docker.com)" = 200 ] \
	&& [ "$(curl -IL -sSo /dev/stderr -w '%{http_code}' --connect-to github.com:443:127.0.0.1:443 https://github.com)" = 200 ] \
	&& [ "$(curl -IL -sSo /dev/stderr -w '%{http_code}' --connect-to google.com:443:127.0.0.1:443 https://google.com)" = 000 ] \
	&& { set +x; printf '%s\n' '========== END OF TEST RUN =========='; } \
	&& apk del --no-cache curl
