include ooz/config.make

# [repos] that use make and all repos.
make_repos := \
	atlas-pack \
  demos/green-field \
	mem \
  nttt \
  ooz \
  solitaire \
	super-patience \
  void
repos := \
  $(make_repos) \
  01 \
  linear-text \
  lineartext.com \
  nature-elsewhere \
  natureelsewhere.com \
  oidoid.com \
  superpatience.com

dist_dir := dist
dist_links := $(repos:%=$(dist_dir)/%/)

test_unit_args ?=
export deno_config = $(PWD)/deno.json

# Repos that link from repo/.
link_root_repos := \
  01 \
  lineartext.com \
  mem \
  natureelsewhere.com \
  oidoid.com \
  superpatience.com
# Repos that link from repo/build.
link_build_repos := linear-text
# Repos that link from demos/repo/dist.
link_demo_dist_repos := $(wildcard demos/*)
# Repos that link from repo/dist.
link_dist_repos := $(filter-out $(link_root_repos) $(link_build_repos) $(link_demo_dist_repos),$(repos))

# Repos that only use watch:bundle for watch.
watch_bundle_repos := \
  nttt \
  ooz \
  solitaire \
  void

format_args ?=

.PHONY: build
build: $(make_repos:%=build-%) | $(dist_links)

# $1 repo
define build_template =
.PHONY: build-$(1)
build-$(1):; $$(make) --directory='$(1)' build
endef

$(foreach repo,$(make_repos),$(eval $(call build_template,$(repo))))

.PHONY: watch
watch: serve $(make_repos:%=watch-%)

.PHONY: serve
serve: | $(dist_links); $(live-server) '$(dist_dir)'

# $1 repo
# $2 targets
define watch_template =
.PHONY: watch-$(1)
watch-$(1):; $$(make) --directory='$(1)' $(2)
endef

$(foreach repo,$(watch_bundle_repos),$(eval $(call watch_template,$(repo),watch-bundle)))
$(eval $(call watch_template,atlas-pack,watch-build watch-bundle))
$(eval $(call watch_template,mem,watch-build))
$(eval $(call watch_template,super-patience,watch-build watch-bundle))
$(eval $(call watch_template,demos/green-field,watch-build watch-bundle))

.PHONY: test
test: test-format test-lint build test-unit

.PHONY: test-format
test-format: format_args += --check

.PHONY: format
format:; $(deno) fmt --config='$(deno_config)' $(format_args)

.PHONY: test-lint
test-lint:; $(deno) lint --config='$(deno_config)' $(if $(value v),,--quiet)

.PHONY: test-unit
test-unit: build; $(deno) test --allow-read=. --config='$(deno_config)' $(test_unit_args)

.PHONY: test-unit-update
test-unit-update: test_unit_args += --allow-write=. -- --update
test-unit-update: test-unit

# $1 repos
# $2 src dir
define ln_template =
$$(patsubst %,$$(dist_dir)/%/,$(1)): | $$(dist_dir)/
  $$(ln) --symbolic '../$$(@:$$(dist_dir)/%=%)$(2)' '$$(@:%/=%)'
endef

# $1 repos
# $2 src dir
define ln_demo_template =
$$(patsubst %,$$(dist_dir)/%/,$(1)): | $$(dist_dir)/ $$(dist_dir)/demos/
  $$(ln) --symbolic '../../$$(@:$$(dist_dir)/%=%)$(2)' '$$(@:%/=%)'
endef

$(eval $(call ln_template,$(link_root_repos),))
$(eval $(call ln_template,$(link_build_repos),build))
$(eval $(call ln_demo_template,$(link_demo_dist_repos),dist))
$(eval $(call ln_template,$(link_dist_repos),dist))

$(dist_dir)/ $(dist_dir)/demos/:; $(mkdir) '$@'

.PHONY: clean
clean:
  for repo in $(make_repos); do $(make) --directory="$$repo" clean; done
  $(rm) '$(dist_dir)/'

.PHONY: rebuild
rebuild:
  $(make) clean
  $(make) build

.PHONY: retest
retest:
  $(make) clean
  $(make) test
