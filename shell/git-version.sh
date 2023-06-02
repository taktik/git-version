#!/usr/bin/env bash

git_version () {
	set +x
	set -e

	# Check for fixed version file
	local VERSION_FILE="git.version"
	if [ -r $VERSION_FILE ]; then
		# Read first line
		local VERSION_LINE
		read -r VERSION_LINE <${VERSION_FILE}
		if [ "$VERSION_LINE" != "" ]; then
			echo "$VERSION_LINE"
			return 0
		fi
	fi

	# Compute information from GIT
	local GIT_DESCRIBE; GIT_DESCRIBE=$(git describe --tags --abbrev=10 --dirty --always --long)
	local GIT_BRANCH; GIT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
	[[ $GIT_BRANCH == */* ]] && local GIT_BRANCH_PREFIX=${GIT_BRANCH%%/*} || local GIT_BRANCH_PREFIX=""
	local GIT_BRANCH_AFTER_PREFIX=${GIT_BRANCH#*/}
	local GIT_TAG_MATCH; GIT_TAG_MATCH=$(git tag --list "${GIT_BRANCH_AFTER_PREFIX}" --list "${GIT_BRANCH_AFTER_PREFIX}.*")
	local GIT_HASH=${GIT_DESCRIBE##*-g}
	local GIT_DESCRIBE_BEFORE_HASH=${GIT_DESCRIBE%-g*}
	local GIT_DISTANCE=${GIT_DESCRIBE_BEFORE_HASH##*-}
	local GIT_TAG=${GIT_DESCRIBE_BEFORE_HASH%-*}

	# Prepare defaults
	local VERSION_MAJOR=0
	local VERSION_MINOR=0
	local VERSION_PATCH=$GIT_DISTANCE
	local VERSION_PRE_RELEASE_IDENTIFIERS=()
	local VERSION_BUILD_IDENTIFIERS=()

	# Compute major/minor/patch version from GIT tag
	if [[ $GIT_TAG =~ ^0*([0-9]+)(\.0*([0-9]+))?(\.0*([0-9]+))? ]]; then
		VERSION_MAJOR=${BASH_REMATCH[1]:-0}
		VERSION_MINOR=${BASH_REMATCH[3]:-0}
		if [[ ${BASH_REMATCH[5]:-0} != "0" ]]; then
			VERSION_PATCH=${BASH_REMATCH[5]}$GIT_DISTANCE
		else
			VERSION_PATCH=$GIT_DISTANCE
		fi
	fi

	# Add branch information - only if GIT not (DETACHED or on master/main branch or on release branch and a tag matches the name after the branch prefix)
	if ! [[ "$GIT_BRANCH" == "" || "$GIT_BRANCH" == "master" || "$GIT_BRANCH" == "main" || ("$GIT_BRANCH_PREFIX" == "release" && "$GIT_TAG_MATCH" != "") ]]; then
		[ "$GIT_BRANCH_PREFIX" != "" ] && VERSION_PRE_RELEASE_IDENTIFIERS+=("${GIT_BRANCH_PREFIX}")

		local BRANCH_INFO=""
		local BRANCH_INFO_DASH_CUT=2
		local BRANCH_INFO_DASH_STR=$GIT_BRANCH_AFTER_PREFIX
		for ((i = 1; i <= BRANCH_INFO_DASH_CUT; i++)); do
			[ "${BRANCH_INFO_DASH_STR%%-*}" != "" ] && { [ "$BRANCH_INFO" != "" ] && BRANCH_INFO="${BRANCH_INFO}-${BRANCH_INFO_DASH_STR%%-*}" || BRANCH_INFO="${BRANCH_INFO}${BRANCH_INFO_DASH_STR%%-*}" ;}
			[[ $BRANCH_INFO_DASH_STR == *-* ]] && BRANCH_INFO_DASH_STR="${BRANCH_INFO_DASH_STR#*-}" || BRANCH_INFO_DASH_STR=""
		done
		BRANCH_INFO="${BRANCH_INFO:0:25}/"

		while [[ $BRANCH_INFO ]]; do
			BRANCH_SEGMENT=${BRANCH_INFO%%/*}
			VERSION_PRE_RELEASE_IDENTIFIERS+=("${BRANCH_SEGMENT}")
			BRANCH_INFO=${BRANCH_INFO#*/}
		done
	fi

	# Add GIT hash as last pre-release identifier
	VERSION_PRE_RELEASE_IDENTIFIERS+=("g$GIT_HASH")

	# Build SEMVER
	local SEMVER="${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}"
	for i in "${!VERSION_PRE_RELEASE_IDENTIFIERS[@]}"; do
		[[ $i == 0 ]] && SEMVER+="-"
		[[ $i -gt 0 ]] && SEMVER+="."
		local VERSION_PRE_RELEASE_IDENTIFIER=${VERSION_PRE_RELEASE_IDENTIFIERS[$i]}
		SEMVER+=${VERSION_PRE_RELEASE_IDENTIFIER//[^a-zA-Z0-9-]/}
	done
	for i in "${!VERSION_BUILD_IDENTIFIERS[@]}"; do
		[[ $i == 0 ]] && SEMVER+="+"
		[[ $i -gt 0 ]] && SEMVER+="."
		local VERSION_BUILD_IDENTIFIER=${VERSION_BUILD_IDENTIFIERS[$i]}
		SEMVER+=${VERSION_BUILD_IDENTIFIER//[^a-zA-Z0-9-]/}
	done

	echo "$SEMVER"
	return 0
}
