SPEC =

.PHONY: test
test: test-stable rubocop

.PHONY: test-stable
test-stable: rails-6.0 rails-6.1 rails-7.0 rails-7.1 rails-7.2

.PHONY: test-all
test-all: test rails-main rails-8.0

.PHONY: update-test
update-test: update test-all
	# git add Gemfile.lock gemfiles/*/Gemfile.lock
	# git commit -m "update dependencies"

.PHONY: rails-6.0
rails-6.0:
	bin/make-helper.sh 6.0 bundle --quiet
	bin/make-helper.sh 6.0 rspec $(SPEC)

.PHONY: rails-6.1
rails-6.1:
	bin/make-helper.sh 6.1 bundle --quiet
	bin/make-helper.sh 6.1 rspec $(SPEC)

.PHONY: rails-7.0
rails-7.0:
	bin/make-helper.sh 7.0 bundle --quiet
	bin/make-helper.sh 7.0 rspec $(SPEC)

.PHONY: rails-7.1
rails-7.1:
	bin/make-helper.sh 7.1 bundle --quiet
	bin/make-helper.sh 7.1 rspec $(SPEC)

.PHONY: rails-7.2
rails-7.2:
	bin/make-helper.sh 7.2 bundle --quiet
	bin/make-helper.sh 7.2 rspec $(SPEC)

.PHONY: rails-8.0
rails-8.0:
	bin/make-helper.sh 8.0 bundle --quiet
	bin/make-helper.sh 8.0 rspec $(SPEC)

.PHONY: rails-main
rails-main:
	bin/make-helper.sh main bundle --quiet
	bin/make-helper.sh main rspec $(SPEC)

.PHONY: setup
setup:
	bin/make-helper.sh 6.0  gem install bundler:2.4.22
	bin/make-helper.sh 6.1  gem install bundler:2.4.22
	bin/make-helper.sh 7.0  gem install bundler:2.4.22
	bin/make-helper.sh 7.1  gem install bundler:2.4.22
	bin/make-helper.sh 7.2  gem install bundler:2.5.6
	bin/make-helper.sh 7.2  gem install bundler:2.5.22
	bin/make-helper.sh main gem install bundler:2.5.22
	bin/make-helper.sh .    gem install bundler:2.4.22

.PHONY: update
update:
	bin/make-helper.sh 6.0  bundle update && bin/make-helper.sh 6.0  bundle clean --force
	bin/make-helper.sh 6.1  bundle update && bin/make-helper.sh 6.1  bundle clean --force
	bin/make-helper.sh 7.0  bundle update && bin/make-helper.sh 7.0  bundle clean --force
	bin/make-helper.sh 7.1  bundle update && bin/make-helper.sh 7.1  bundle clean --force
	bin/make-helper.sh 7.2  bundle update && bin/make-helper.sh 7.2  bundle clean --force
	bin/make-helper.sh 8.0  bundle update && bin/make-helper.sh 8.0  bundle clean --force
	bin/make-helper.sh main bundle update && bin/make-helper.sh main bundle clean --force
	bin/make-helper.sh .    bundle update && bin/make-helper.sh .    bundle clean --force

.PHONY: rubocop
rubocop:
	bin/make-helper.sh . bundle --quiet
	bin/make-helper.sh . rake rubocop:autocorrect

.PHONY: docs
docs:
	bin/make-helper.sh . bundle --quiet
	bin/make-helper.sh . yard doc --markup markdown 'lib/**/*.rb' - README.md CHANGELOG.md LICENSE

.PHONY: texd-docker
texd-docker:
	rm -rvf tmp/jobs tmp/refs tmp/home
	mkdir -p tmp/jobs tmp/refs tmp/home
	docker run --rm \
		--name texd-dev \
		-p 127.0.0.1:2201:2201 \
		-e HOME=/texd/home \
		-v $$(pwd)/tmp/jobs:/texd/jobs \
		-v $$(pwd)/tmp/refs:/texd/refs \
		-v $$(pwd)/tmp/home:/texd/home \
		-u $$(id -u):$$(id -g) \
		ghcr.io/digineo/texd \
			--job-directory /texd/jobs \
			--reference-store dir:///texd/refs \
			--retention-policy=purge-on-start \
			--keep-jobs always
