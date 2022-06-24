#!/bin/bash

source ../env_files/config.env

# docs component release version
export RELEASE_VERSION="$CONFLUENT"

# Jenkins sets CHANGE_ID for pull request builds with pull request ID
if [[ $CHANGE_ID ]]; then
  PULL_REQUEST_ID=$CHANGE_ID
elif [[ -z $JENKINS_HOME ]]; then  # Not running on Jenkins: Stage local changes separately to avoid conflict with Jenkins staging
  PULL_REQUEST_ID='local'
fi

# Check to see if we should sync current or not
# Do not sync "current" for PRs as "current" is used by Jenkins staging & promotion
SYNC_CURRENT=false
if [[ -z $PULL_REQUEST_ID ]]; then
    SYNC_CURRENT=true
fi

# `BRANCH` is the global setting for build branches of Confluent packages
#
# IMPORTANT:  This setting affects only those CP projects whose documentation will be
#             pulled in via git-cloning their repositories such as schema-registry.
#             In contrast, the CP documentation for Kafka is NOT affected by this setting.
#
# Be aware that projects may have different naming conventions for branches.
# If needed, make use of project-specific overrides as described below.
#
# Examples
# --------
# BRANCH="origin/master" # for snapshots
# BRANCH="origin/3.2.x" # for development/maintenance branches
# BRANCH="v3.2.0" # tag
#
# Internal note: We MUST `export` these variables so that the shell environment
# can automatically pass them as environment variables to the Makefile.
#
# IMPORTANT: For *branches*, this must be a remote ref, i.e. "orgin/foobar", not just "foobar"!
export BRANCH="origin/6.0.8-post"

export MAVEN_OPTS="-XX:MaxPermSize=128M -Dhttps.protocols=TLSv1.2"

# Staging S3 bucket to which we deploy the new documentation.
DOCS_BUCKET="staging-docs-independent.confluent.io"

# Docs component repo name, example: docs-cloud, docs-connect, docs-ansible
DOCS_COMPONENT_NAME="docs-ansible"
DOCS_COMPONENT_PAGE_NAME="ansible"

# Production S3 bucket that contains our production documentation repository.
#
# NOTE: You should never need to modify this setting!
DOCS_BUCKET_PRODUCTION=""

BUCKET_POLICY_FILE_TEMPLATE="bucket-policy-public-read.json.template"
BUCKET_POLICY_FILE="bucket-policy-public-read.json"


### Misc settings
###
HTML_DIRECTORY="_build/html" # local directory; stores generated documentation in HTML form


###
### Input validation of settings defined above
###
if [ -z "$RELEASE_VERSION" ]; then
  echo "ERROR: RELEASE_VERSION must be set"
  exit 1
fi
if [ -z "$RELEASE_VERSION_MIN_LENGTH" ]; then
  declare -r RELEASE_VERSION_MIN_LENGTH=5 # 5 for "x.y.z"
fi
if [ ${#RELEASE_VERSION} -lt $RELEASE_VERSION_MIN_LENGTH ]; then
  echo "ERROR: RELEASE_VERSION must have a length >= ${RELEASE_VERSION_MIN_LENGTH} (it currently has length ${#RELEASE_VERSION})"
  exit 1
fi
if [ -z "$HTML_DIRECTORY" ]; then
  echo "ERROR: HTML_DIRECTORY must be set"
  exit 1
fi

# Ensure that buckets are configured.
if [ -z "DOCS_BUCKET" ]; then
  echo "ERROR: DOCS_BUCKET must be set"
  exit 1
fi

