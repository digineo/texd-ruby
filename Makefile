SPEC =

.PHONY: test
test: rails60 rails61 rails70 rubocop

.PHONY: rails60
rails60:
ifeq ($(SPEC),)
	export BUNDLE_GEMFILE=gemfiles/rails-6.0 && bundle --quiet && bundle exec rake spec
else
	export BUNDLE_GEMFILE=gemfiles/rails-6.0 && bundle --quiet && bundle exec rspec $(SPEC)
endif

.PHONY: rails61
rails61:
ifeq ($(SPEC),)
	export BUNDLE_GEMFILE=gemfiles/rails-6.1 && bundle --quiet && bundle exec rake spec
else
	export BUNDLE_GEMFILE=gemfiles/rails-6.1 && bundle --quiet && bundle exec rspec $(SPEC)
endif

.PHONY: rails70
rails70:
ifeq ($(SPEC),)
	export BUNDLE_GEMFILE=gemfiles/rails-7.0 && bundle --quiet && bundle exec rake spec
else
	export BUNDLE_GEMFILE=gemfiles/rails-7.0 && bundle --quiet && bundle exec rspec $(SPEC)
endif

.PHONY: update
update:
	export BUNDLE_GEMFILE=gemfiles/rails-6.0 && bundle update
	export BUNDLE_GEMFILE=gemfiles/rails-6.1 && bundle update
	export BUNDLE_GEMFILE=gemfiles/rails-7.0 && bundle update
	export BUNDLE_GEMFILE=Gemfile            && bundle update

.PHONY: rubocop
rubocop:
	export BUNDLE_GEMFILE=Gemfile && bundle --quiet && bundle exec rake rubocop:auto_correct

.PHONY: docs
docs:
	export BUNDLE_GEMFILE=Gemfile && bundle --quiet && bundle exec yard doc --markup markdown 'lib/**/*.rb' - README.md CHANGELOG.md LICENSE

.PHONY: texd-docker
texd-docker:
	mkdir -p tmp/jobs tmp/refs
	docker run --rm \
		--name texd-dev \
		-p 127.0.0.1:2201:2201 \
		-v $$(pwd)/tmp/jobs:/texd \
		-v $$(pwd)/tmp/refs:/refs \
		--user=$(id -u):$(id -g) \
			digineode/texd --reference-store dir:///refs
