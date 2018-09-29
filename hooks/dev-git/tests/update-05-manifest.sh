#!/bin/bash
# Tests for update-05-manifest hook
# Copyright 2018 Michał Górny
# Distributed under the terms of the GNU General Public License v2 or later

. "${BASH_SOURCE%/*}"/lib.sh
HOOK_PATH=${BASH_SOURCE%/*}/../update-05-manifest
[[ ${HOOK_PATH} == /* ]] || HOOK_PATH=${PWD}/${HOOK_PATH}

make_manifest() {
	mkdir -p app-foo/bar || die
	echo "${1}" > app-foo/bar/Manifest || die
	git add app-foo/bar/Manifest || die
	git commit -q -m 'Add Manifest' || die
}

# Error message patterns
FAIL_THICK="Thin Manifests can contain only DIST lines!
*"
FAIL_HASH="Disallowed hash set in Manifest!
*"

tbegin "Testing valid Manifest"
make_manifest "DIST empty.file 0 BLAKE2B 786a02f742015903c6c6fd852552d272912f4740e15847618a86e217f71f5419d25e1031afee585313896444934eb04b903a685b1448b755d56f701afe9be2ce SHA512 cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"
test_success

tbegin "Testing thick Manifest"
make_manifest "DIST empty.file 0 BLAKE2B 786a02f742015903c6c6fd852552d272912f4740e15847618a86e217f71f5419d25e1031afee585313896444934eb04b903a685b1448b755d56f701afe9be2ce SHA512 cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e
EBUILD foo-1.ebuild 0 BLAKE2B 786a02f742015903c6c6fd852552d272912f4740e15847618a86e217f71f5419d25e1031afee585313896444934eb04b903a685b1448b755d56f701afe9be2ce SHA512 cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3"
test_failure "${FAIL_THICK}entry: EBUILD foo-1.ebuild *"

tbegin "Testing obsolete checksum set"
make_manifest "DIST empty.file 0 SHA256 e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 SHA512 cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e WHIRLPOOL 19fa61d75522a4669b44e39c1d2e1726c530232130d407f89afee0964997f7a73e83be698b288febcf88e3e03c4f0757ea8964e59b63d93708b138cc42a66eb3"
test_failure "${FAIL_HASH}"

tbegin "Testing combined new + obsolete checksum set"
make_manifest "DIST empty.file 0 BLAKE2B 786a02f742015903c6c6fd852552d272912f4740e15847618a86e217f71f5419d25e1031afee585313896444934eb04b903a685b1448b755d56f701afe9be2ce SHA256 e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 SHA512 cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e WHIRLPOOL 19fa61d75522a4669b44e39c1d2e1726c530232130d407f89afee0964997f7a73e83be698b288febcf88e3e03c4f0757ea8964e59b63d93708b138cc42a66eb3"
test_failure "${FAIL_HASH}"

tbegin "Testing partial (BLAKE2B) checksum set"
make_manifest "DIST empty.file 0 BLAKE2B 786a02f742015903c6c6fd852552d272912f4740e15847618a86e217f71f5419d25e1031afee585313896444934eb04b903a685b1448b755d56f701afe9be2ce"
test_failure "${FAIL_HASH}"

tbegin "Testing partial (SHA512) checksum set"
make_manifest "DIST empty.file 0 SHA512 cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"
test_failure "${FAIL_HASH}"

tbegin "Testing empty checksum set"
make_manifest "DIST empty.file 0"
test_failure "${FAIL_HASH}"
