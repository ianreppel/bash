#!/bin/bash
# Databaseline code repository
# 
# Code for post: Setting up Scala for Spark App Development
# Base URL:      https://databaseline.tech
# Author:        Ian Hellström
# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
PROJECT="$1"
ORIGINAL_FOLDER="$(pwd)"
CFG_FILE="app.cfg"
if [ -r "$CFG_FILE" ]; then
  echo "Sourcing application configuration..." && source "$CFG_FILE"
else
  echo "No application configuration found." && exit 1
fi
# -----------------------------------------------------------------------------
# Create main folder and plugins file
# -----------------------------------------------------------------------------
cd "$SCALA_FOLDER"
mkdir "$PROJECT"
cd "$PROJECT"
mkdir project
echo "addSbtPlugin(\"com.eed3si9n\" % \"sbt-assembly\" % \"$SBT_VERSION\")

// See: http://www.47deg.com/blog/improve-your-scala-code-with-sbt
addSbtPlugin(\"org.scoverage\" % \"sbt-scoverage\" % \"$SBT_SCOVERAGE_VERSION\")
addSbtPlugin(\"com.orrsella\" % \"sbt-stats\" % \"$SBT_STATS_VERSION\")" > project/plugins.sbt
# -----------------------------------------------------------------------------
# Create build.sbt
# -----------------------------------------------------------------------------
echo "name := \"$PROJECT\"
version := \"0.0.1\"
scalaVersion := \"$SCALA_VERSION\"
organization := \"$ORGANIZATION\"

val sparkVersion = \"$SPARK_VERSION\"
val suffix = \"provided\"
val test = \"test\"

scalacOptions ++= Seq(
  \"-unchecked\",
  \"-feature\",
  \"-deprecation\",
  \"-encoding\", \"UTF-8\",
  \"-Xlint\",
  \"-Xfatal-warnings\",
  \"-Ywarn-adapted-args\",
  \"-Ywarn-dead-code\",
  \"-Ywarn-numeric-widen\",
  \"-Ywarn-unused\",
  \"-Ywarn-unused-import\",
  \"-Ywarn-value-discard\"
)

libraryDependencies ++= Seq(
  \"org.apache.spark\"  %% \"spark-core\"       % sparkVersion            % suffix,
  \"org.apache.spark\"  %% \"spark-sql\"        % sparkVersion            % suffix,  
//  \"org.apache.spark\"  %% \"spark-hive\"       % sparkVersion            % suffix,
//  \"org.apache.spark\"  %% \"spark-streaming\"  % sparkVersion            % suffix,
//  \"org.apache.spark\"  %% \"spark-graphx\"     % sparkVersion            % suffix,
//  \"org.apache.spark\"  %% \"spark-mllib\"      % sparkVersion            % suffix,
  \"org.apache.hadoop\" % \"hadoop-client\"     % \"$HADOOP_VERSION\"     % suffix,
  \"org.scalatest\"     %% \"scalatest\"        % \"$SCALATEST_VERSION\"  % test,
) " > build.sbt
# -----------------------------------------------------------------------------
# Create folder structure
# -----------------------------------------------------------------------------
mkdir -p src/{main,test}/scala/$ORG_FOLDER
# -----------------------------------------------------------------------------
# Create main entry point
# -----------------------------------------------------------------------------
echo "package $ORGANIZATION

import org.apache.spark._
import org.apache.spark.sql._

object $PROJECT extends App {
  val spark = SparkSession
   .builder()
   .appName(\"$PROJECT\")
   .enableHiveSupport()
   .getOrCreate()

  import spark.implicits._

  try {
    // ...
  } finally {
    spark.stop()
  }
}" > src/main/scala/$ORG_FOLDER/$PROJECT.scala
# -----------------------------------------------------------------------------
# Create UnitSpec class with common mixins
# -----------------------------------------------------------------------------
echo "package $ORGANIZATION

import org.scalatest._

abstract class UnitSpec extends FlatSpec with Matchers with OptionValues with BeforeAndAfterAll" > src/test/scala/$ORG_FOLDER/UnitSpec.scala
# -----------------------------------------------------------------------------
# Create unit test scaffolding
# -----------------------------------------------------------------------------
echo "package $ORGANIZATION

import org.apache.spark._
import org.apache.spark.sql._

class "$PROJECT"Spec extends UnitSpec {
    val spark = SparkSession
   .builder()
   .appName(\"Suite: $PROJECT\")
   .setMaster(\"local[*]\")
   .enableHiveSupport()
   .getOrCreate()

  import spark.implicits._

  \"A $PROJECT\" should \"...\" in {

  }

  it should \"...\" in {

  }

  override def afterAll() {
    spark.stop()
  }
}" > src/test/scala/$ORG_FOLDER/"$PROJECT"Spec.scala
# -----------------------------------------------------------------------------
# Return to original location
# -----------------------------------------------------------------------------
cd $ORIGINAL_FOLDER
