# ## Overview
# Makefile for common project tasks, delegating to make.sh for parity across POSIX and Windows.
#
# ## Usage
# make <target> [COMP=<component_name>]

.PHONY: audit update_results register_bento_boxes test_canary_6os test_matrix_6os local_tests_toolchain local_tests_languages local_tests_databases test local_tests_all test_component

test: local_tests_all

local_tests_all:
	./make.sh local_tests_all

local_tests_toolchain:
	./make.sh local_tests_toolchain

local_tests_languages:
	./make.sh local_tests_languages

local_tests_databases:
	./make.sh local_tests_databases

test_component:
	@if [ -z "$(COMP)" ]; then echo "Usage: make test_component COMP=<component_name>"; exit 1; fi
	./make.sh test_component $(COMP)

audit:
	./make.sh audit

update_results:
	./make.sh update_results

register_bento_boxes:
	./make.sh register_bento_boxes

test_canary_6os:
	./make.sh test_canary_6os

test_matrix_6os:
	./make.sh test_matrix_6os
