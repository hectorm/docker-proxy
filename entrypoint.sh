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

# Define the Traefik entrypoints.
_IFS=${IFS}; IFS=",$(printf '\nx')"; IFS=${IFS%x}
for upstream in ${PROXY_UPSTREAMS?}; do
	port=$(printf '%s' "${upstream:?}" | cut -d: -f2)

	export "TRAEFIK_ENTRYPOINTS_port${port:?}"="true"
	export "TRAEFIK_ENTRYPOINTS_port${port:?}_ADDRESS"=":${port:?}/tcp"
done
IFS=$_IFS

# If the first arg is "-f" or "--some-option", or our command is a valid Traefik subcommand,
# let's invoke it through Traefik instead.
if [ "${1#-}" != "${1:?}" ] || traefik "${1:?}" --help >/dev/null 2>&1; then
	set -- traefik "${@}"
fi

exec "${@}"
