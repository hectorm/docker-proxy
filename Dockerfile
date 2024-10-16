# syntax=docker.io/docker/dockerfile:1

FROM docker.io/traefik:3.1.6@sha256:f703a2ac2ddf75f6e06c9cccac7f158765e2ab42d642b04e79e2e3d7355c2ddc

COPY --chown=0:0 --chmod=644 ./config/traefik/dynamic/proxy.yml /etc/traefik/dynamic/proxy.yml
COPY --chown=0:0 --chmod=755 ./entrypoint.sh /entrypoint.sh

ENV RESOLVCONF_PATH=/etc/resolv.conf
ENV RESOLVCONF_NAMESERVER_1=1.0.0.1
ENV RESOLVCONF_NAMESERVER_2=1.1.1.1

ENV TRAEFIK_GLOBAL_CHECKNEWVERSION=false
ENV TRAEFIK_GLOBAL_SENDANONYMOUSUSAGE=false
ENV TRAEFIK_PROVIDERS_FILE_DIRECTORY=/etc/traefik/dynamic/
ENV TRAEFIK_PROVIDERS_FILE_WATCH=false
ENV TRAEFIK_API=false
ENV TRAEFIK_PING=true

HEALTHCHECK --start-period=30s --interval=10s --timeout=5s --retries=1 CMD ["traefik", "healthcheck"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["traefik"]

RUN set -eu \
	&& apk add --no-cache curl openssl \
	&& { printf '%s\n' '========== START OF TEST RUN =========='; set -x; } \
	&& { PROXY_UPSTREAMS=google.com:443,smtp.gmail.com:465,smtp.gmail.com:587:catchall /entrypoint.sh traefik & } \
	&& timeout 120 sh -euc 'sleep 1; until traefik healthcheck; do sleep 1; done' \
	&& [ "$(curl -IL -sSo /dev/stderr -w '%{http_code}' --connect-to github.com:443:127.0.0.1:443 https://github.com)" = 000 ] \
	&& [ "$(curl -IL -sSo /dev/stderr -w '%{http_code}' --connect-to google.com:443:127.0.0.1:443 https://google.com)" = 200 ] \
	&& { printf 'QUIT\r\n' | openssl s_client -servername smtp.gmail.com -connect 127.0.0.1:465 -brief 1>&2; } \
	&& { printf 'QUIT\r\n' | openssl s_client -servername smtp.gmail.com -connect 127.0.0.1:587 -starttls smtp -brief 1>&2; } \
	&& { set +x; printf '%s\n' '========== END OF TEST RUN =========='; } \
	&& apk del --no-cache curl
