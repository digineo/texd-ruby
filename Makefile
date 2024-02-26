SPEC =

.PHONY: test
test: test-stable rubocop

.PHONY: test-stable
test-stable: rails-6.0 rails-6.1 rails-7.0 rails-7.1

.PHONY: test-all
test-all: test rails-main

# TODO: make rails-* tasks DRY?

.PHONY: rails-6.0
rails-6.0:
	export BUNDLE_GEMFILE=gemfiles/rails-6.0/Gemfile && bundle --quiet && bundle exec rspec $(SPEC)

.PHONY: rails-6.1
rails-6.1:
	export BUNDLE_GEMFILE=gemfiles/rails-6.1/Gemfile && bundle --quiet && bundle exec rspec $(SPEC)

.PHONY: rails-7.0
rails-7.0:
	export BUNDLE_GEMFILE=gemfiles/rails-7.0/Gemfile && bundle --quiet && bundle exec rspec $(SPEC)

.PHONY: rails-7.1
rails-7.1:
	export BUNDLE_GEMFILE=gemfiles/rails-7.1/Gemfile && bundle --quiet && bundle exec rspec $(SPEC)

.PHONY: rails-main
rails-main:
	export BUNDLE_GEMFILE=gemfiles/rails-main/Gemfile && bundle --quiet && bundle exec rspec $(SPEC)

.PHONY: update
update:
	export BUNDLE_GEMFILE=gemfiles/rails-6.0/Gemfile  && bundle update
	export BUNDLE_GEMFILE=gemfiles/rails-6.1/Gemfile  && bundle update
	export BUNDLE_GEMFILE=gemfiles/rails-7.0/Gemfile  && bundle update
	export BUNDLE_GEMFILE=gemfiles/rails-7.1/Gemfile  && bundle update
	export BUNDLE_GEMFILE=gemfiles/rails-main/Gemfile && bundle update
	export BUNDLE_GEMFILE=Gemfile                     && bundle update

.PHONY: rubocop
rubocop:
	export BUNDLE_GEMFILE=Gemfile && bundle --quiet && bundle exec rake rubocop:autocorrect

.PHONY: docs
docs:
	export BUNDLE_GEMFILE=Gemfile && bundle --quiet && bundle exec yard doc --markup markdown 'lib/**/*.rb' - README.md CHANGELOG.md LICENSE

.PHONY: texd-docker
texd-docker:
	rm -rvf tmp/jobs tmp/refs
	mkdir -p tmp/jobs tmp/refs
	docker run --rm \
		--name texd-dev \
		-p 127.0.0.1:2201:2201 \
		-v $$(pwd)/tmp/jobs:/texd \
		-v $$(pwd)/tmp/refs:/refs \
		-u $$(id -u):$$(id -g) \
		ghcr.io/digineo/texd \
			--reference-store dir:///refs \
			--retention-policy=purge-on-start \
			--keep-jobs always
