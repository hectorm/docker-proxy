# syntax=docker.io/docker/dockerfile:1

FROM docker.io/traefik:3.3.5@sha256:104204dadedf5d1284f8ef8f97f705649ac81aa6f7a6c9abf13e2c59245b8abc

COPY --chown=0:0 --chmod=644 ./config/traefik/dynamic/proxy.yml /etc/traefik/dynamic/proxy.yml
COPY --chown=0:0 --chmod=755 ./entrypoint.sh /entrypoint.sh

ENV RESOLVCONF_PATH=/etc/resolv.conf
ENV RESOLVCONF_NAMESERVER_1=1.0.0.1
ENV RESOLVCONF_NAMESERVER_2=1.1.1.1
ENV RESOLVCONF_NAMESERVER_3=8.8.8.8

ENV TRAEFIK_GLOBAL_CHECKNEWVERSION=false
ENV TRAEFIK_GLOBAL_SENDANONYMOUSUSAGE=false
ENV TRAEFIK_PROVIDERS_FILE_DIRECTORY=/etc/traefik/dynamic/
ENV TRAEFIK_PROVIDERS_FILE_WATCH=false
ENV TRAEFIK_API=false
ENV TRAEFIK_PING=true

ENV PROXY_HTTP_TO_HTTPS_REDIRECT=true

HEALTHCHECK --start-period=30s --interval=10s --timeout=5s --retries=1 CMD ["traefik", "healthcheck"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["traefik"]

RUN sh -eu <<-'EOF'
	apk add --no-cache curl knot-utils openssl
	{ printf '%s\n' '========== START OF TEST RUN =========='; set -x; }
	PROXY_UPSTREAMS='
		google.com:443:tls,
		smtp.gmail.com:465:tls,
		smtp.gmail.com:587:tcp,
		1.1.1.1:53:udp,
		1.1.1.1:53:tcp,
		1.1.1.1:853:tls,
		dns0.eu:853:tls,
		dns0.eu:853:udp
	' /entrypoint.sh traefik &
	timeout 120 sh -euc 'sleep 1; until traefik healthcheck; do sleep 1; done'
	[ "$(curl -kvIL -sSo /dev/stderr -w '%{http_code}' --resolve github.com:443:127.0.0.1 https://github.com)" = 404 ]
	[ "$(curl -kvIL -sSo /dev/stderr -w '%{http_code}' --resolve github.com:443:127.0.0.1 --resolve github.com:80:127.0.0.1 http://github.com)" = 404 ]
	[ "$(curl -kvIL -sSo /dev/stderr -w '%{http_code}' --resolve google.com:443:127.0.0.1 https://google.com)" = 200 ]
	[ "$(curl -kvIL -sSo /dev/stderr -w '%{http_code}' --resolve google.com:443:127.0.0.1 --resolve google.com:80:127.0.0.1 http://google.com)" = 200 ]
	printf 'QUIT\r\n' | openssl s_client -servername smtp.gmail.com -connect 127.0.0.1:465 -verify_return_error -brief
	printf 'QUIT\r\n' | openssl s_client -servername smtp.gmail.com -connect 127.0.0.1:587 -verify_return_error -brief -starttls smtp
	kdig @127.0.0.1:53 google.com
	kdig @127.0.0.1:53 +tcp google.com
	kdig @127.0.0.1:853 +tls +tls-host=1.1.1.1 google.com
	kdig @127.0.0.1:853 +tls +tls-host=dns0.eu google.com
	kdig @127.0.0.1:853 +quic +tls-host=dns0.eu google.com
	{ set +x; printf '%s\n' '========== END OF TEST RUN =========='; }
	apk del curl knot-utils openssl
EOF
