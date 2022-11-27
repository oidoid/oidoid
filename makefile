include oidlib/config.make

# [repos] that use make and all repos.
make_repos := \
	atlas-pack \
	mem \
  natural \
  nttt \
  oidlib \
  solitaire \
	sublime-solitaire
repos := \
  $(make_repos) \
  01 \
  linear-text \
  lineartext.com \
  nature-elsewhere \
  natureelsewhere.com \
  oidoid.com

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
  oidoid.com
# Repos that link from repo/build.
link_build_repos := linear-text
# Repos that link from repo/dist.
link_dist_repos := $(filter-out $(link_root_repos) $(link_build_repos),$(repos))

# Repos that only use watch:bundle for watch.
watch_bundle_repos := \
  oidlib \
  natural \
  nttt \
  solitaire

.PHONY: build
build: $(make_repos:%=build\:%) | $(dist_links)

# $1 repo
define build_template =
.PHONY: build\:$(1)
build\:$(1):; $$(make) --directory='$(1)' build
endef

$(foreach repo,$(make_repos),$(eval $(call build_template,$(repo))))

.PHONY: watch
watch: serve $(make_repos:%=watch\:%)

.PHONY: serve
serve: | $(dist_links); $(live-server) '$(dist_dir)'

# $1 repo
# $2 targets
define watch_template =
.PHONY: watch\:$(1)
watch\:$(1):; $$(make) --directory='$(1)' $(2)
endef

$(foreach repo,$(watch_bundle_repos),$(eval $(call watch_template,$(repo),watch\:bundle)))
$(eval $(call watch_template,atlas-pack,watch\:build watch\:bundle))
$(eval $(call watch_template,mem,watch\:build))
$(eval $(call watch_template,sublime-solitaire,watch\:build watch\:bundle))

.PHONY: test
test: test\:format test\:lint build test\:unit

.PHONY: test\:format
test\:format:; $(deno) fmt --check --config='$(deno_config)'

.PHONY: test\:lint
test\:lint:; $(deno) lint --config='$(deno_config)' $(if $(value v),,--quiet)

.PHONY: test\:unit
test\:unit: build; $(deno) test --allow-read=. --config='$(deno_config)' $(test_unit_args)

.PHONY: test\:unit\:update
test\:unit\:update: test_unit_args += --allow-write=. -- --update
test\:unit\:update: test\:unit

# $1 repos
# $2 src dir
define ln_template =
$$(patsubst %,$$(dist_dir)/%/,$(1)): | $$(dist_dir)/
  $$(ln) --symbolic '../$$(@:$$(dist_dir)/%=%)$(2)' '$$(@:%/=%)'
endef

$(eval $(call ln_template,$(link_root_repos),))
$(eval $(call ln_template,$(link_build_repos),build))
$(eval $(call ln_template,$(link_dist_repos),dist))

$(dist_dir)/:; $(mkdir) '$@'

.PHONY: clean
clean:
  for repo in $(make_repos); do $(make) --directory="$$repo" clean; done
  $(rm) '$(dist_dir)/'
