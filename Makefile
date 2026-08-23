# ## Overview
# Makefile for common project tasks.
#
# ## Usage
# make <target>

.PHONY: local_tests_toolchain local_tests_languages local_tests_databases test local_tests_all test_component

test: local_tests_all

local_tests_all:
	./tests/run_local_tests.sh all

local_tests_toolchain:
	./tests/run_local_tests.sh toolchains

local_tests_languages:
	./tests/run_local_tests.sh languages

local_tests_databases:
	./tests/run_local_tests.sh databases

test_component:
	@if [ -z "$(COMP)" ]; then echo "Usage: make test_component COMP=<component_name>"; exit 1; fi
	./tests/run_local_tests.sh $(COMP)
