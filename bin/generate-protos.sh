#!/usr/bin/env bash

set -eo pipefail

DIR=`dirname "$0"`
OUTPUT_DIR=$DIR/../lib/apollo-studio-tracing/tracing/proto

echo "Removing old client"
rm -f $OUTPUT_DIR/apollo.proto $OUTPUT_DIR/apollo_pb.rb

echo "Downloading latest Apollo Protobuf IDL"
curl --silent --output lib/apollo-studio-tracing/tracing/proto/apollo.proto https://raw.githubusercontent.com/apollographql/apollo-server/main/packages/apollo-engine-reporting-protobuf/src/reports.proto

echo "Generating Ruby client stubs"
protoc -I lib/apollo-studio-tracing/tracing/proto --ruby_out lib/apollo-studio-tracing/tracing/proto lib/apollo-studio-tracing/tracing/proto/apollo.proto
