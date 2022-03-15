SPEC =

.PHONY: test
test: rails60 rails61 rails70 rubocop

.PHONY: rails60
rails60:
ifeq ($(SPEC),)
	export BUNDLE_GEMFILE=Gemfile-6.0 && bundle --quiet && bundle exec rake spec
else
	export BUNDLE_GEMFILE=Gemfile-6.0 && bundle --quiet && bundle exec rspec $(SPEC)
endif

.PHONY: rails61
rails61:
ifeq ($(SPEC),)
	export BUNDLE_GEMFILE=Gemfile-6.1 && bundle --quiet && bundle exec rake spec
else
	export BUNDLE_GEMFILE=Gemfile-6.1 && bundle --quiet && bundle exec rspec $(SPEC)
endif

.PHONY: rails70
rails70:
ifeq ($(SPEC),)
	export BUNDLE_GEMFILE=Gemfile && bundle --quiet && bundle exec rake spec
else
	export BUNDLE_GEMFILE=Gemfile && bundle --quiet && bundle exec rspec $(SPEC)
endif

.PHONY: update
update:
	export BUNDLE_GEMFILE=Gemfile-6.0 && bundle update
	export BUNDLE_GEMFILE=Gemfile-6.1 && bundle update
	export BUNDLE_GEMFILE=Gemfile     && bundle update

.PHONY: rubocop
rubocop:
	export BUNDLE_GEMFILE=Gemfile && bundle --quiet && bundle exec rake rubocop:auto_correct
