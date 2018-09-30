#!/bin/bash
# Tests for git hooks
# Copyright 2018 Michał Górny
# Distributed under the terms of the GNU General Public License v2 or later

. /lib/gentoo/functions.sh

TESTS=(
	update-04-utf8.sh
	update-05-manifest.sh
	update-06-copyright.sh
)

ret=0
for t in "${TESTS[@]}"; do
	einfo "${t} tests:"
	eindent
	(
		. "${BASH_SOURCE%/*}/${t}"
	)
	: $(( ret |= ${?} ))
	eoutdent
done

[[ ${ret} -eq 0 ]] || eerror "Some of the tests failed."
exit "${ret}"
