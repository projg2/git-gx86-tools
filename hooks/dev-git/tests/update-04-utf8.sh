#!/bin/bash
# Tests for update-04-utf8 hook
# Copyright 2018 Michał Górny
# Distributed under the terms of the GNU General Public License v2 or later

. "${BASH_SOURCE%/*}"/lib.sh
HOOK_PATH=${BASH_SOURCE%/*}/../update-04-utf8
[[ ${HOOK_PATH} == /* ]] || HOOK_PATH=${PWD}/${HOOK_PATH}

FAIL_MSG="Commit * contains invalid UTF-8 in the commit metadata"

export GIT_COMMITTER_NAME='UTF-8 Guy ĄĆĘŁŃÓŚŹŻ'
export GIT_COMMITTER_EMAIL='utf8@example.com'
export GIT_AUTHOR_NAME=${GIT_COMMITTER_NAME}
export GIT_AUTHOR_EMAIL=${GIT_COMMITTER_EMAIL}

tbegin "Testing valid UTF-8 commit"
git commit -q --allow-empty -m "Valid UTF-8: ąćęłńóśźż"
test_success

tbegin "Testing commit with invalid UTF-8 in commit message"
git -c i18n.commitencoding=iso-8859-2 commit -q --allow-empty -m $'Invalid UTF-8: \261\346'
test_failure "${FAIL_MSG}"

tbegin "Testing commit with invalid UTF-8 in committer's name"
export GIT_COMMITTER_NAME=$'ISO-8859-2 guy \261\346'
git -c i18n.commitencoding=iso-8859-2 commit -q --allow-empty -m "Some message"
test_failure "${FAIL_MSG}"
export GIT_COMMITTER_NAME=${GIT_AUTHOR_NAME}

tbegin "Testing commit with invalid UTF-8 in author's name"
export GIT_AUTHOR_NAME=$'ISO-8859-2 guy \261\346'
git -c i18n.commitencoding=iso-8859-2 commit -q --allow-empty -m "Some message"
test_failure "${FAIL_MSG}"
export GIT_AUTHOR_NAME=${GIT_COMMITTER_NAME}

exit "${TEST_RET}"
