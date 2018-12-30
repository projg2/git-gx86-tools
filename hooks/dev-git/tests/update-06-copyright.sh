#!/bin/bash
# Tests for update-06-copyright hook
# Copyright 2018 Michał Górny
# Distributed under the terms of the GNU General Public License v2 or later

. "${BASH_SOURCE%/*}"/lib.sh
HOOK_PATH=${BASH_SOURCE%/*}/../update-06-copyright
[[ ${HOOK_PATH} == /* ]] || HOOK_PATH=${PWD}/${HOOK_PATH}

# Override ldapsearch for the purpose of the tests
ldapsearch() {
	case ${GL_USER} in
		fakedev@gentoo.org)
			cat <<-EOF
				dn: uid=fakedev,ou=devs,dc=gentoo,dc=org
				cn: I. M. Developer
				gecos: I. M. Developer
			EOF
			;;
		polisher@gentoo.org)
			cat <<-EOF
				dn: uid=polisher,ou=devs,dc=gentoo,dc=org
				cn:: xITEh8SZxYLFhMOzxZvFusW8IFBvbGlzaGVyCg==
				gecos: Acelnoszz Polisher
			EOF
			;;
		otherdev@gentoo.org)
			cat <<-EOF
				dn: uid=otherdev,ou=devs,dc=gentoo,dc=org
				cn: John O. Developer
				gecos: John O. Developer
			EOF
			;;
	esac
}

# Error message patterns
FAIL_NO_SIGNOFF="*: missing Signed-off-by on commit
*"
FAIL_EMAIL="*: no Signed-off-by line matching committer's e-mail address found!
*"
FAIL_SYNTAX="*: malformed Signed-off-by (should be: real name <email>)!
*"
FAIL_REALNAME="*: name in Signed-off-by does not match realname in LDAP!
*"
FAIL_LICENSE="*: DCO-1.1 Signed-off-by used on license directory!
*"

# Non-developer commit tests (for repos that allow those)
export GL_USER=nondev@example.com
export GIT_COMMITTER_NAME='Non A. Dev'
export GIT_COMMITTER_EMAIL=${GL_USER}
export GIT_AUTHOR_NAME=${GIT_COMMITTER_NAME}
export GIT_AUTHOR_EMAIL=${GIT_COMMITTER_EMAIL}

einfo "Simple non-developer commit tests"
eindent

tbegin "Valid GCO sign-off"
git commit --allow-empty -m "A commit

Signed-off-by: ${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}>" -q
test_success

tbegin "Multiple sign-offs (including valid)"
git commit --allow-empty -m "A commit

Signed-off-by: Somebody Else <else@example.com>
Some-other-tag: blah blah
Signed-off-by: ${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}>
Signed-off-by: Also Him <him@example.com>" -q
test_success

tbegin "No sign-off"
git commit --allow-empty -m "A commit" -q
test_failure "${FAIL_NO_SIGNOFF}"

tbegin "Mismatched e-mail address in sign-off"
git commit --allow-empty -m "A commit

Signed-off-by: ${GIT_COMMITTER_NAME} <foo@example.com>" -q
test_failure "${FAIL_EMAIL}"

tbegin "Different name in sign-off"
git commit --allow-empty -m "A commit

Signed-off-by: Foo Bar <${GIT_COMMITTER_EMAIL}>" -q
test_success

tbegin "Case-insensitive e-mail matching"
git commit --allow-empty -m "A commit

Signed-off-by: ${GIT_COMMITTER_NAME^^} <${GIT_COMMITTER_EMAIL^^}>" -q
test_success

tbegin "Linux DCO sign-off"
git commit --allow-empty -m "A commit

Signed-off-by: ${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}> (DCO-1.1)" -q
test_success

eoutdent

einfo "License directory tests"
eindent

tbegin "GCO sign-off on licenses directory"
mkdir -p licenses || die
echo 'Unmodifiable license' > licenses/mylicense || die
git add licenses/mylicense
git commit -m "A commit with license

Signed-off-by: ${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}>" -q
test_success

tbegin "Linux DCO sign-off on licenses directory"
mkdir -p licenses || die
echo 'Unmodifiable license' > licenses/mylicense || die
git add licenses/mylicense
git commit -m "A commit with license

Signed-off-by: ${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}> (DCO-1.1)" -q
test_failure "${FAIL_LICENSE}"

eoutdent

einfo "Syntax check tests"
eindent

tbegin "Invalid sign-off (no e-mail address)"
git commit --allow-empty -m "A commit

Signed-off-by: ${GIT_COMMITTER_NAME}" -q
test_failure "${FAIL_SYNTAX}"

tbegin "Invalid sign-off (no name)"
git commit --allow-empty -m "A commit

Signed-off-by: <${GIT_COMMITTER_EMAIL}>" -q
test_failure "${FAIL_SYNTAX}"

tbegin "Invalid + valid sign-off (should be rejected)"
git commit --allow-empty -m "A commit

Signed-off-by: ${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}>
Signed-off-by: Yo Momma" -q
test_failure "${FAIL_SYNTAX}"

eoutdent

# Now with a different author
export GIT_AUTHOR_NAME='Somebody Else'
export GIT_AUTHOR_EMAIL='selse@example.com'

einfo "Committer != author, non-developer tests"
eindent

tbegin "Committer != author (non-dev) with valid GCO sign-off"
git commit --allow-empty -m "A commit

Signed-off-by: ${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}>" -q
test_success

tbegin "Committer != author (non-dev) with only author sign-off"
git commit --allow-empty -m "A commit

Signed-off-by: ${GIT_AUTHOR_NAME} <${GIT_AUTHOR_EMAIL}>" -q
test_failure "${FAIL_EMAIL}"

eoutdent

# Developer commit tests
export GL_USER=fakedev@gentoo.org
export GIT_COMMITTER_NAME='I. M. Developer'
export GIT_COMMITTER_EMAIL=${GL_USER}
export GIT_AUTHOR_NAME=${GIT_COMMITTER_NAME}
export GIT_AUTHOR_EMAIL=${GIT_COMMITTER_EMAIL}

einfo "Simple developer commit tests"
eindent

tbegin "Valid GCO sign-off"
git commit --allow-empty -m "A commit

Signed-off-by: ${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}>" -q
test_success

tbegin "E-mail mismatch"
git commit --allow-empty -m "A commit

Signed-off-by: ${GIT_COMMITTER_NAME} <fakedev@example.com>" -q
test_failure "${FAIL_EMAIL}"

tbegin "Real name mismatch"
git commit --allow-empty -m "A commit

Signed-off-by: fakedev <${GIT_COMMITTER_EMAIL}>" -q
test_failure "${FAIL_REALNAME}"

tbegin "Case insensitivity"
git commit --allow-empty -m "A commit

Signed-off-by: ${GIT_COMMITTER_NAME^^} <${GIT_COMMITTER_EMAIL^^}>" -q
test_success

tbegin "Comment after realname"
git commit --allow-empty -m "A commit

Signed-off-by: ${GIT_COMMITTER_NAME} (foobarbaz) <${GIT_COMMITTER_EMAIL}>" -q
test_success

eoutdent

export GIT_AUTHOR_NAME='Somebody Else'
export GIT_AUTHOR_EMAIL='selse@example.com'

einfo "Proxied commit tests"
eindent

tbegin "Developer + author GCO sign-off"
git commit --allow-empty -m "A commit

Signed-off-by: ${GIT_AUTHOR_NAME} <${GIT_AUTHOR_EMAIL}>
Signed-off-by: ${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}>" -q
test_success

tbegin "Only developer GCO sign-off"
git commit --allow-empty -m "A commit

Signed-off-by: ${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}>" -q
test_success

tbegin "Only author GCO sign-off"
git commit --allow-empty -m "A commit

Signed-off-by: ${GIT_AUTHOR_NAME} <${GIT_AUTHOR_EMAIL}>" -q
test_failure "${FAIL_EMAIL}"

eoutdent

einfo "Hardcore unicode tests"
eindent

export GL_USER=polisher@gentoo.org
export GIT_COMMITTER_NAME='Ąćęłńóśźż Polisher'
export GIT_COMMITTER_EMAIL=${GL_USER}
export GIT_AUTHOR_NAME=${GIT_COMMITTER_NAME}
export GIT_AUTHOR_EMAIL=${GIT_COMMITTER_EMAIL}

tbegin "All uppercase"
git commit --allow-empty -m "A commit

Signed-off-by: ĄĆĘŁŃÓŚŹŻ POLISHER <${GIT_COMMITTER_EMAIL}>" -q
test_success

tbegin "All lowercase"
git commit --allow-empty -m "A commit

Signed-off-by: ąćęłńóśźż polisher <${GIT_COMMITTER_EMAIL}>" -q
test_success

tbegin "Mixed case"
git commit --allow-empty -m "A commit

Signed-off-by: ąĆĘŁńóśŹŻ Polisher <${GIT_COMMITTER_EMAIL}>" -q
test_success

tbegin "ASCII (GECOS) version"
git commit --allow-empty -m "A commit

Signed-off-by: Acelnoszz Polisher <${GIT_COMMITTER_EMAIL}>" -q
test_success

tbegin "Uppercase GECOS"
git commit --allow-empty -m "A commit

Signed-off-by: ACELNOSZZ POLISHER <${GIT_COMMITTER_EMAIL}>" -q
test_success

tbegin "Lowercase GECOS"
git commit --allow-empty -m "A commit

Signed-off-by: acelnoszz polisher <${GIT_COMMITTER_EMAIL}>" -q
test_success

eoutdent

export GL_USER=otherdev@gentoo.org
export GIT_COMMITTER_NAME='I. M. Developer'
export GIT_COMMITTER_EMAIL=fakedev@gentoo.org
export GIT_AUTHOR_NAME=${GIT_COMMITTER_NAME}
export GIT_AUTHOR_EMAIL=${GIT_COMMITTER_EMAIL}

einfo "Committer != pusher tests"
eindent

tbegin "Valid GCO sign-off"
git commit --allow-empty -m "A commit

Signed-off-by: ${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}>" -q
test_success

tbegin "Pusher GCO sign-off only"
git commit --allow-empty -m "A commit

Signed-off-by: John O. Developer <${GL_USER}>" -q
test_failure "${FAIL_EMAIL}"

tbegin "Committer realname mismatch (XFAIL)"
git commit --allow-empty -m "A commit

Signed-off-by: Wrong Name Here <${GIT_COMMITTER_EMAIL}>" -q
test_success

eoutdent

einfo "Merge commit tests"
eindent

tbegin "Merge commit with B-branch commit missing sign-off"
git checkout -q -b test-branch
git commit --allow-empty -m "A commit" -q
git checkout -q master
export GIT_COMMITTER_NAME='John O. Developer'
export GIT_COMMITTER_EMAIL=${GL_USER}
git commit --allow-empty -m "Another master commit

Signed-off-by: ${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}>" -q
git merge -q -m "Test merge commit

Signed-off-by: ${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}>" -q test-branch
test_failure "${FAIL_NO_SIGNOFF}"

tbegin "Merge commit missing sign-off"
git checkout -q -b test-branch
git commit --allow-empty -m "A commit

Signed-off-by: ${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}>" -q
git checkout -q master
git commit --allow-empty -m "Another master commit

Signed-off-by: ${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}>" -q
git merge -q -m "Test merge commit" -q test-branch
test_failure "${FAIL_NO_SIGNOFF}"

eoutdent

einfo "Branch addition / removal tests"
eindent

tbegin "Forked branch with sign-off present"
git checkout -q -b test-branch
git commit --allow-empty -m "Commit with sign-off

Signed-off-by: ${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}>" -q
test_branch_success test-branch

tbegin "Forked branch with new non-signed commit"
git checkout -q -b test-branch
git commit --allow-empty -m "Commit without sign-off" -q
test_branch_failure test-branch "${FAIL_NO_SIGNOFF}"

tbegin "Copy of master branch"
git checkout -q -b test-branch
test_branch_success test-branch

tbegin "New independent branch with sign-off"
git checkout --orphan test-branch -q
git commit --allow-empty -m "Commit with sign-off

Signed-off-by: ${GIT_COMMITTER_NAME} <${GIT_COMMITTER_EMAIL}>" -q
test_branch_success test-branch

tbegin "New independent branch without sign-off"
git checkout --orphan test-branch -q
git commit --allow-empty -m "Commit without sign-off" -q
test_branch_failure test-branch "${FAIL_NO_SIGNOFF}"

tbegin "Branch removal"
test_branch_removal

eoutdent

exit "${TEST_RET}"
