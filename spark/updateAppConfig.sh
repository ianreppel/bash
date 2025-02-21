#!/bin/bash
# Code for post: Setting up Scala for Spark App Development
# Base URL:      https://ianreppel.org
# Author:        Ian Reppel
# -------------------------------------------------------------------------------------------------
# Global definitions 
# -------------------------------------------------------------------------------------------------
FUNCTIONS="$(realpath ../functions.sh)"
if [ -r "$FUNCTIONS" ]; then
  source "$FUNCTIONS"
else
  echo "Cannot load functions file." && exit 1
fi

CFG_FILE="$(basename app.cfg)"
if [ -r "$CFG_FILE" ]; then
  source "$CFG_FILE"
else
  echo "Cannot load configuration file." && exit 2
fi
# -------------------------------------------------------------------------------------------------
# Internal configuration: VERSION prefix|groupId|ArtifactId
# -------------------------------------------------------------------------------------------------
MAVEN_URL="http://search.maven.org/solrsearch/select?"

MAVEN_CONFIG=("SCALATEST|org.scalatest|scalatest_" \
              "SPARK|org.apache.spark|spark-core_" \
              "HADOOP|org.apache.hadoop|hadoop-client" \
              "SBT_SCOVERAGE|org.scoverage|sbt-scoverage" \
              "SBT_STATS|com.orrsella|sbt-stats")
# -------------------------------------------------------------------------------------------------
# Scala and sbt versions
# -------------------------------------------------------------------------------------------------
CURR_SCALA_VERSION=$(scala -version 2>&1 | sed 's/.*version \([[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*\).*/\1/')
CURR_SCALA_VERSION_SHORT=$(echo $CURR_SCALA_VERSION | sed 's/\([[:digit:]]*\.[[:digit:]]*\)\..*/\1/')
CURR_SBT_VERSION=$(sbt --version 2>&1 | sed 's/.*version \([[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*\).*/\1/')
# -------------------------------------------------------------------------------------------------
# Update Scala and sbt version configurations in CFG_FILE
# -------------------------------------------------------------------------------------------------
if [ $CURR_SCALA_VERSION != $SCALA_VERSION ]; then
  sed -i "s/^SCALA_VERSION=.*$/SCALA_VERSION=\"$CURR_SCALA_VERSION\" # $SCALA_VERSION/" "$CFG_FILE"
fi

if [ $CURR_SBT_VERSION != $SBT_VERSION ]; then
  sed -i "s/^SBT_VERSION=.*$/SBT_VERSION=\"$CURR_SBT_VERSION\" # $SBT_VERSION/" "$CFG_FILE"
fi
# -------------------------------------------------------------------------------------------------
# Update version configurations in CFG_FILE based on MAVEN_CFG
# -------------------------------------------------------------------------------------------------
for i in "${!MAVEN_CONFIG[@]}"; do
  lib="${MAVEN_CONFIG[i]}"
  libConfig="(${lib//|/ })""
  libId="${libConfig[0]}"
  libGroupId="${libConfig[1]}""
  libArtifactId="${libConfig[2]}"

  # Add short Scala version if artifact configuration end with underscore
  if [ "${libArtifactId: -1}" = "_" ]; then
    libArtifactId=$libArtifactId$CURR_SCALA_VERSION_SHORT
  fi

  # Build REST URL and extract version (already sorted)
  query="q=g:\"$libGroupId\" AND a:\"$libArtifactId\""
  opts="&core=gav&rows=1&wt=json"
  libUrl="$(encodeURL $MAVEN_URL$query$opts)"
  libInfo="$(curl -s -X GET "$libUrl")"
  libVersion="$(echo $libInfo | sed 's/.*"v":"\([^"]*\)".*/\1/')"

  # Build configuration string and replace in CFG_FILE
  configString=""$libId"_VERSION=\""$libVersion"\""
  sed -i "s/^"$libId"_VERSION=.*$/"$libId"_VERSION=\"$libVersion\"/" "$CFG_FILE"
done
