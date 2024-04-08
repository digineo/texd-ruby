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

# determine Ruby version from Rails version. rails-main (7.2+) requires
# Ruby 3.1+, the rest is kept at 2.7 for now.
case "$rails_ver" in
".")
	log "Using to ruby-2.7 for project root"
	gemdir=""
	ruby_ver="2.7"
	;;
"main")
	log "Using to ruby-3.1 for rails-main"
	gemdir="gemfiles/rails-main"
	ruby_ver="3.1"
	;;
*)
	log "Using to ruby-2.7 for rails-${rails_ver}"
	gemdir="gemfiles/rails-${rails_ver}"
	ruby_ver="2.7"

	# check if valid/known
	if [ ! -d "${root}/${gemdir}" ]; then
		err "No configuration found for Rails version ${rails_ver}."
	fi
	;;
esac

# configure rbenv and bundler
# XXX: RBENV_VERSION + RBENV_GEMSETS should work, but last time I tried
#      it produced a mess. Need to verify in an isolated checkout...
echo "$ruby_ver"         > "${root}/.ruby-version"
echo "./.gems/$ruby_ver" > "${root}/.ruby-gemset"
export BUNDLE_GEMFILE="./$gemdir/Gemfile"

# run CMD; prefix with "bundle exec", unless CMD starts with "bundle"
case "$1" in
"bundle")
	exec "$@"
	;;
*)
	exec bundle exec "$@"
	;;
esac