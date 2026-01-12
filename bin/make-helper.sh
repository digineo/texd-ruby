#!/bin/sh
#
# SYNOPSIS
#	make-helper.sh RAILSVER CMD [...]
#
#	Runs the given command in a specifc Ruby/Rails environment.
#	This is intended as a helper for ../Makefile.
#
# OPTIONS
#	RAILSVER
#		shall be a Rails version (like "6.1" or "main") or dontate the
#		project itself ("."). For the former, a matching directory must
#		exist in the "../gemfiles" directory.
#		Depending on the associated Ruby version (defined in this script),
#		the rbenv environment is switched, and the command is run within
#		that environment.
#	CMD [...]
#		shall be a Ruby command and its arguments. It is prefixed with
#		`bundle exec`, unless it already starts with `bundle`.
#
# ENVIRONMENT
#
#	USE_DOCKER
#		When set to "1", CMD is run in a Docker container, with the
#		current UID/GID.
#
# KNOWN ISSUES
#	- This *requires* rbenv and rbenv-gemset to work properly. This is not
#	  documented in the README.
#	- Chaining multiple commands is awkward and does more work than necessary:
#	  Running "bundle update && bundle exec rspec" would translate to something
#	  like "bin/make-helper.sh . bundle update && bin/make-helper.sh . rspec".
#	  Maybe a Make macro would be better suited...

root="$(readlink -f $(dirname $0)/..)"

log() {
	local msg="$1"
	echo "\e[30m${msg}\e[0m"
}
err() {
	local msg="$1"
	echo "\e[31;1m${msg}\e[0m"
	exit 1
}

ruby_ver=
gemdir=
rails_ver="$1"
shift

# Determine Ruby version from Rails version.
# By default, we use Ruby 3.2, with the following exceptions:
#
# - rails-main requires 3.3+
case "$rails_ver" in
".")
	gemdir=""
	ruby_ver="3.2"
	;;
"main")
	gemdir="gemfiles/rails-main"
	ruby_ver="3.3"
	;;
*)
	gemdir="gemfiles/rails-${rails_ver}"
	ruby_ver="3.2"

	# check if valid/known
	if [ ! -d "${root}/${gemdir}" ]; then
		err "No configuration found for Rails version ${rails_ver}."
	fi
	;;
esac

# prefix CMD with "bundle exec", unless CMD starts with "bundle" or "gem"
case "$1" in
"bundle"|"gem")
	# nothing to do
	;;
*)
	set -- bundle exec "$@"
	;;
esac


# When USE_DOCKER is set, run the command in a Docker container.
# Here, the following options become relevant or change their meaning:
#
# - TEXD_ENDPOINT must now point to the address of the texd instance
#   *from within the test container*. In particular, this can be the
#   container name of the texd container.
# - TEXD_LINK specifies the name of the container running texd. When
#   omitted, we assume that container was started via `make texd-docker`,
#   which starts a container named "texd-dev". If this is not the case,
#   you need to explicitly set the env var.
if [ "$USE_DOCKER" = "1" ]; then
	dockerhome=".docker/project"
	if [ -n "$gemdir" ]; then
		dockerhome=".docker/$(basename "$gemdir")"
	fi

	mkdir -p "$dockerhome"

	link_container=
	texd_endpoint="--env TEXD_ENDPOINT"

	if [ -n "TEXD_LINK" ]; then
		link_container="--link ${TEXD_LINK}"
		texd_endpoint="--env TEXD_ENDPOINT=http://${TEXD_LINK}:2201/"
	elif [ -n "$(docker container ls -qf 'name=texd-dev' | tr -d '\n')" ]; then
		link_container="--link texd-dev"
		texd_endpoint="--env TEXD_ENDPOINT=http://texd-dev:2201/"
	fi

	exec docker run --rm \
		--user $(id -u):$(id -g) \
		--volume "$(pwd):/texd" \
		--workdir /texd \
		$link_container \
		$texd_endpoint \
		--env HOME="/texd/${dockerhome}" \
		--env GEM_HOME="/texd/${dockerhome}/gems" \
		--env BUNDLE_PATH="/texd/${dockerhome}/bundle" \
		--env BUNDLE_GEMFILE="/texd/${gemdir}/Gemfile" \
		--env BUNDLE_RETRY=3 \
		"ruby:${ruby_ver}" "$@"
else
	# configure rbenv and bundler
	# XXX: RBENV_VERSION + RBENV_GEMSETS should work, but last time I tried
	#      it produced a mess. Need to verify in an isolated checkout...
	if [ "z$ruby_ver" != "z$(cat "${root}/.ruby-version")" ]; then
		log "switching Ruby to $ruby_ver"
		echo "$ruby_ver" > "${root}/.ruby-version"
	fi
	if [ "z./${gemdir}/.gems" != "z$(cat "${root}/.ruby-gemset")" ]; then
		log "switching gemset to $gemdir"
		echo "./${gemdir}/.gems" > "${root}/.ruby-gemset"
	fi
	export BUNDLE_GEMFILE="./$gemdir/Gemfile"

	# run CMD
	exec "$@"
fi
