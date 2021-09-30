scope := minor
main_branch_name := $(shell git symbolic-ref refs/remotes/origin/HEAD | sed "s@^refs/remotes/origin/@@")

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

fmt:  ## Run terraform fmt
	terraform fmt

repo-init:  ## initialize this repository from template
	@# Replaces the repository_url in .chglog/config*.yml with this repo's https URL.
	@# We use ',' in sed as a substitute separator to not conflict with characters in the URL.
	@repository_url="$(shell git remote get-url --push origin | sed -e 's,git@github.com:,https://github.com/,' -e 's,.git$$,,')"; \
	for conf in .chglog/config*.yml; do \
		sed -i.bak "s,^\\([[:space:]]*repository_url:\\).*\$$,\\1 $${repository_url}," $${conf}; \
		rm $${conf}.bak; \
	done

alpha:  ## args: scope - publish an alpha version
	@semtag alpha -v "$(shell semtag alpha -s ${scope} -o)+$(shell git rev-parse --short HEAD)"

clean-alpha:  ## deletes all alpha versions and tags
	@repo_name="$(shell git remote get-url --push origin | xargs -I{} basename -s .git {})"; \
	module_provider="$$(echo $${repo_name} | cut -d- -f2)"; \
	module_name="$$(echo $${repo_name} | cut -d- -f3-)"; \
	if [[ -n $${module_provider} ]] && [[ -n $${module_name} ]]; then \
		if [[ -n $${TERRAFORM_CLOUD_TOKEN} ]]; then \
			echo "Deleting alpha versions from Terraform Cloud"; \
			curl  --header "Authorization: Bearer $${TERRAFORM_CLOUD_TOKEN}" \
				https://app.terraform.io/api/registry/v1/modules/wave/$${module_name}/$${module_provider} \
				2>/dev/null | \
			jq .versions | \
			grep -- '-alpha.' | \
			cut -d'"' -f2 | \
			while read version; do \
				if [[ -n $${version} ]]; then \
					curl --header "Authorization: Bearer $${TERRAFORM_CLOUD_TOKEN}" \
						--header "Content-Type: application/vnd.api+json" \
						--request POST https://app.terraform.io/api/v2/registry-modules/actions/delete/wave/$${module_name}/$${module_provider}/$${version}; \
				fi; \
			done; \
			echo "Deleting alpha tags from local git"; \
			git tag | grep -- '-alpha.' | xargs -I{} git tag -d {}; \
			echo "Deleting alpha tags from remote git"; \
			git ls-remote --tags --refs --quiet | awk '/-alpha./ {print $$NF}' | xargs -I{} git push origin :{}; \
		else \
			echo "Error: No TERRAFORM_CLOUD_TOKEN variable found"; \
		fi; \
	else \
		echo "Error: Could not compute this module's name and provider"; \
	fi

get-release:  ## args: scope - get the next release tag with scope `scope`
	@semtag final -s ${scope} -f -o

publish:  ## args: scope - publish the next release tag with scope `scope`. Must be on main branch.
	@git checkout ${main_branch_name}; \
	git pull; \
	echo "About to create tag $(shell semtag final -s ${scope} -o)"; \
	read -p "Are you sure? [y/n] " -n 1 -r; \
	echo; \
	if [[ $${REPLY} =~ ^[Yy]$$ ]]; then \
		semtag final -s ${scope}; \
	fi;

changelog:  ## args: scope - prefill a changelog update
	@cp CHANGELOG.md CHANGELOG.md.tmp
	@nexttag="$(shell semtag final -s ${scope} -f -o)"; \
	prefill=$$(git-chglog --tag-filter-pattern '^[vV]?\d+\.\d+\.\d+$$' --next-tag $${nexttag} $${nexttag}); \
	( \
		( \
			`# print out from existing changelog up to the '[Unreleased]' heading` \
			awk '/^## \[Unreleased\]/ {exit} {print}' CHANGELOG.md.tmp; \
			`# print our new changelog prefill` \
			echo "$${prefill}"; \
			`# print out from existing changelog everything after the old '[Unreleased]' heading` \
			awk 'f;/^## \[Unreleased\]/{f=1}' CHANGELOG.md.tmp \
		) | \
		`# don't include old changelog links` \
		awk '/^\[[Uu]nreleased\]: https:\/\/github.com/ {exit} {print}'; \
		`# write new changelog links` \
		git-chglog --tag-filter-pattern '^[vV]?\d+\.\d+\.\d+$$' --next-tag $${nexttag} -c .chglog/config_links.yml \
	) | cat -s > CHANGELOG.md; \
	rm -f CHANGELOG.md.tmp; \
	echo "Changelog has been prefilled for version $${nexttag}. Please check and modify as necessary."

.PHONY: help fmt alpha clean-alpha changelog get-release publish repo-init
.DEFAULT_GOAL := help
