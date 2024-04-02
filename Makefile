SPEC =

.PHONY: test
test: test-stable rubocop

.PHONY: test-stable
test-stable: rails-6.0 rails-6.1 rails-7.0 rails-7.1

.PHONY: test-all
test-all: test rails-main

.PHONY: rails-6.0
rails-6.0:
	bin/make-helper.sh 6.0 bundle --quiet && \
	bin/make-helper.sh 6.0 rspec $(SPEC)

.PHONY: rails-6.1
rails-6.1:
	bin/make-helper.sh 6.1 bundle --quiet && \
	bin/make-helper.sh 6.1 rspec $(SPEC)

.PHONY: rails-7.0
rails-7.0:
	bin/make-helper.sh 7.0 bundle --quiet && \
	bin/make-helper.sh 7.0 rspec $(SPEC)

.PHONY: rails-7.1
rails-7.1:
	bin/make-helper.sh 7.1 bundle --quiet && \
	bin/make-helper.sh 7.1 rspec $(SPEC)

.PHONY: rails-main
rails-main:
	bin/make-helper.sh main bundle --quiet && \
	bin/make-helper.sh main rspec $(SPEC)

.PHONY: update
update:
	bin/make-helper.sh 6.0  bundle update
	bin/make-helper.sh 6.1  bundle update
	bin/make-helper.sh 7.0  bundle update
	bin/make-helper.sh 7.1  bundle update
	bin/make-helper.sh main bundle update
	bin/make-helper.sh .    bundle update

.PHONY: rubocop
rubocop:
	bin/make-helper.sh . bundle --quiet && \
	bin/make-helper.sh . rake rubocop:autocorrect

.PHONY: docs
docs:
	bin/make-helper.sh . bundle --quiet && \
	bin/make-helper.sh . yard doc --markup markdown 'lib/**/*.rb' - README.md CHANGELOG.md LICENSE

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
