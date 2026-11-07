.PHONY: test lint check

test:
	bash tests/smoke.sh

lint:
	bash -n kurenai install.sh uninstall.sh tests/smoke.sh
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck -x kurenai install.sh uninstall.sh tests/smoke.sh; \
	else \
		echo 'shellcheck no instalado; se omite'; \
	fi

check: lint test
