SPEC =

.PHONY: test
test: rails-6.0 rails-6.1 rails-7.0 rubocop

# TODO: make rails-* tasks DRY?

.PHONY: rails-6.0
rails-6.0:
ifeq ($(SPEC),)
	export BUNDLE_GEMFILE=gemfiles/rails-6.0/Gemfile && bundle --quiet && bundle exec rake spec
else
	export BUNDLE_GEMFILE=gemfiles/rails-6.0/Gemfile && bundle --quiet && bundle exec rspec $(SPEC)
endif

.PHONY: rails-6.1
rails-6.1:
ifeq ($(SPEC),)
	export BUNDLE_GEMFILE=gemfiles/rails-6.1/Gemfile && bundle --quiet && bundle exec rake spec
else
	export BUNDLE_GEMFILE=gemfiles/rails-6.1/Gemfile && bundle --quiet && bundle exec rspec $(SPEC)
endif

.PHONY: rails-7.0
rails-7.0:
ifeq ($(SPEC),)
	export BUNDLE_GEMFILE=gemfiles/rails-7.0/Gemfile && bundle --quiet && bundle exec rake spec
else
	export BUNDLE_GEMFILE=gemfiles/rails-7.0/Gemfile && bundle --quiet && bundle exec rspec $(SPEC)
endif

ifeq ($(SPEC),)
else
endif

.PHONY: update
update:
	export BUNDLE_GEMFILE=gemfiles/rails-6.0/Gemfile  && bundle update
	export BUNDLE_GEMFILE=gemfiles/rails-6.1/Gemfile  && bundle update
	export BUNDLE_GEMFILE=gemfiles/rails-7.0/Gemfile  && bundle update
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
		digineode/texd \
			--reference-store dir:///refs \
			--retention-policy=purge-on-start \
			--keep-jobs always
