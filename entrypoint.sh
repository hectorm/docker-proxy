#!/bin/sh

set -eu

# Overwrite the resolv.conf file.
if [ -n "${RESOLVCONF_PATH:-}" ] && touch "${RESOLVCONF_PATH:?}" 2>/dev/null; then
	sed '/^$/d' > "${RESOLVCONF_PATH:?}" <<-EOF
		${RESOLVCONF_NAMESERVER_1:+nameserver ${RESOLVCONF_NAMESERVER_1:?}}
		${RESOLVCONF_NAMESERVER_2:+nameserver ${RESOLVCONF_NAMESERVER_2:?}}
		${RESOLVCONF_NAMESERVER_3:+nameserver ${RESOLVCONF_NAMESERVER_3:?}}
		${RESOLVCONF_OPTIONS:+options ${RESOLVCONF_OPTIONS:?}}
		${RESOLVCONF_SEARCH:+search ${RESOLVCONF_SEARCH:?}}
	EOF
fi

# Define the Traefik entrypoints for the proxy upstreams.
_IFS=${IFS}; IFS="$(printf ' \t\n,')";
for upstream in ${PROXY_UPSTREAMS:-}; do
	port=$(printf '%s' "${upstream:?}" | cut -d: -f2)
	kind=$(printf '%s' "${upstream:?}" | cut -d: -f3)

	case "${kind:?}" in
		"tcp"|"tls") proto='tcp' ;;
		"udp") proto='udp' ;;
		*) printf "Invalid kind: %s\n" "${kind:?}" >&2; exit 1 ;;
	esac

	export "TRAEFIK_ENTRYPOINTS_proxy${port:?}${proto:?}"="true"
	export "TRAEFIK_ENTRYPOINTS_proxy${port:?}${proto:?}_ADDRESS"=":${port:?}/${proto:?}"
done
IFS=$_IFS

# Define the Traefik entrypoint for HTTP to HTTPS redirection.
if [ "${PROXY_HTTP_TO_HTTPS_REDIRECT:?}" = "true" ]; then
	export TRAEFIK_ENTRYPOINTS_http="true"
	export TRAEFIK_ENTRYPOINTS_http_ADDRESS=":80/tcp"
fi

# If the first arg is "-f" or "--some-option", or our command is a valid Traefik subcommand,
# let's invoke it through Traefik instead.
if [ "${1#-}" != "${1:?}" ] || traefik "${1:?}" --help >/dev/null 2>&1; then
	set -- traefik "${@}"
fi

exec "${@}"
