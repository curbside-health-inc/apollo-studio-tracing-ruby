# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: apollo.proto

require 'google/protobuf'

require 'google/protobuf/timestamp_pb'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("apollo.proto", :syntax => :proto3) do
    add_message "mdg.engine.proto.Trace" do
      optional :start_time, :message, 4, "google.protobuf.Timestamp"
      optional :end_time, :message, 3, "google.protobuf.Timestamp"
      optional :duration_ns, :uint64, 11
      optional :root, :message, 14, "mdg.engine.proto.Trace.Node"
      optional :is_incomplete, :bool, 33
      optional :signature, :string, 19
      optional :unexecutedOperationBody, :string, 27
      optional :unexecutedOperationName, :string, 28
      optional :details, :message, 6, "mdg.engine.proto.Trace.Details"
      optional :client_name, :string, 7
      optional :client_version, :string, 8
      optional :http, :message, 10, "mdg.engine.proto.Trace.HTTP"
      optional :cache_policy, :message, 18, "mdg.engine.proto.Trace.CachePolicy"
      optional :query_plan, :message, 26, "mdg.engine.proto.Trace.QueryPlanNode"
      optional :full_query_cache_hit, :bool, 20
      optional :persisted_query_hit, :bool, 21
      optional :persisted_query_register, :bool, 22
      optional :registered_operation, :bool, 24
      optional :forbidden_operation, :bool, 25
      optional :field_execution_weight, :double, 31
    end
    add_message "mdg.engine.proto.Trace.CachePolicy" do
      optional :scope, :enum, 1, "mdg.engine.proto.Trace.CachePolicy.Scope"
      optional :max_age_ns, :int64, 2
    end
    add_enum "mdg.engine.proto.Trace.CachePolicy.Scope" do
      value :UNKNOWN, 0
      value :PUBLIC, 1
      value :PRIVATE, 2
    end
    add_message "mdg.engine.proto.Trace.Details" do
      map :variables_json, :string, :string, 4
      optional :operation_name, :string, 3
    end
    add_message "mdg.engine.proto.Trace.Error" do
      optional :message, :string, 1
      repeated :location, :message, 2, "mdg.engine.proto.Trace.Location"
      optional :time_ns, :uint64, 3
      optional :json, :string, 4
    end
    add_message "mdg.engine.proto.Trace.HTTP" do
      optional :method, :enum, 1, "mdg.engine.proto.Trace.HTTP.Method"
      map :request_headers, :string, :message, 4, "mdg.engine.proto.Trace.HTTP.Values"
      map :response_headers, :string, :message, 5, "mdg.engine.proto.Trace.HTTP.Values"
      optional :status_code, :uint32, 6
    end
    add_message "mdg.engine.proto.Trace.HTTP.Values" do
      repeated :value, :string, 1
    end
    add_enum "mdg.engine.proto.Trace.HTTP.Method" do
      value :UNKNOWN, 0
      value :OPTIONS, 1
      value :GET, 2
      value :HEAD, 3
      value :POST, 4
      value :PUT, 5
      value :DELETE, 6
      value :TRACE, 7
      value :CONNECT, 8
      value :PATCH, 9
    end
    add_message "mdg.engine.proto.Trace.Location" do
      optional :line, :uint32, 1
      optional :column, :uint32, 2
    end
    add_message "mdg.engine.proto.Trace.Node" do
      optional :original_field_name, :string, 14
      optional :type, :string, 3
      optional :parent_type, :string, 13
      optional :cache_policy, :message, 5, "mdg.engine.proto.Trace.CachePolicy"
      optional :start_time, :uint64, 8
      optional :end_time, :uint64, 9
      repeated :error, :message, 11, "mdg.engine.proto.Trace.Error"
      repeated :child, :message, 12, "mdg.engine.proto.Trace.Node"
      oneof :id do
        optional :response_name, :string, 1
        optional :index, :uint32, 2
      end
    end
    add_message "mdg.engine.proto.Trace.QueryPlanNode" do
      oneof :node do
        optional :sequence, :message, 1, "mdg.engine.proto.Trace.QueryPlanNode.SequenceNode"
        optional :parallel, :message, 2, "mdg.engine.proto.Trace.QueryPlanNode.ParallelNode"
        optional :fetch, :message, 3, "mdg.engine.proto.Trace.QueryPlanNode.FetchNode"
        optional :flatten, :message, 4, "mdg.engine.proto.Trace.QueryPlanNode.FlattenNode"
        optional :defer, :message, 5, "mdg.engine.proto.Trace.QueryPlanNode.DeferNode"
        optional :condition, :message, 6, "mdg.engine.proto.Trace.QueryPlanNode.ConditionNode"
      end
    end
    add_message "mdg.engine.proto.Trace.QueryPlanNode.SequenceNode" do
      repeated :nodes, :message, 1, "mdg.engine.proto.Trace.QueryPlanNode"
    end
    add_message "mdg.engine.proto.Trace.QueryPlanNode.ParallelNode" do
      repeated :nodes, :message, 1, "mdg.engine.proto.Trace.QueryPlanNode"
    end
    add_message "mdg.engine.proto.Trace.QueryPlanNode.FetchNode" do
      optional :service_name, :string, 1
      optional :trace_parsing_failed, :bool, 2
      optional :trace, :message, 3, "mdg.engine.proto.Trace"
      optional :sent_time_offset, :uint64, 4
      optional :sent_time, :message, 5, "google.protobuf.Timestamp"
      optional :received_time, :message, 6, "google.protobuf.Timestamp"
    end
    add_message "mdg.engine.proto.Trace.QueryPlanNode.FlattenNode" do
      repeated :response_path, :message, 1, "mdg.engine.proto.Trace.QueryPlanNode.ResponsePathElement"
      optional :node, :message, 2, "mdg.engine.proto.Trace.QueryPlanNode"
    end
    add_message "mdg.engine.proto.Trace.QueryPlanNode.DeferNode" do
      optional :primary, :message, 1, "mdg.engine.proto.Trace.QueryPlanNode.DeferNodePrimary"
      repeated :deferred, :message, 2, "mdg.engine.proto.Trace.QueryPlanNode.DeferredNode"
    end
    add_message "mdg.engine.proto.Trace.QueryPlanNode.ConditionNode" do
      optional :condition, :string, 1
      optional :if_clause, :message, 2, "mdg.engine.proto.Trace.QueryPlanNode"
      optional :else_clause, :message, 3, "mdg.engine.proto.Trace.QueryPlanNode"
    end
    add_message "mdg.engine.proto.Trace.QueryPlanNode.DeferNodePrimary" do
      optional :node, :message, 1, "mdg.engine.proto.Trace.QueryPlanNode"
    end
    add_message "mdg.engine.proto.Trace.QueryPlanNode.DeferredNode" do
      repeated :depends, :message, 1, "mdg.engine.proto.Trace.QueryPlanNode.DeferredNodeDepends"
      optional :label, :string, 2
      optional :path, :message, 3, "mdg.engine.proto.Trace.QueryPlanNode.ResponsePathElement"
      optional :node, :message, 4, "mdg.engine.proto.Trace.QueryPlanNode"
    end
    add_message "mdg.engine.proto.Trace.QueryPlanNode.DeferredNodeDepends" do
      optional :id, :string, 1
      optional :defer_label, :string, 2
    end
    add_message "mdg.engine.proto.Trace.QueryPlanNode.ResponsePathElement" do
      oneof :id do
        optional :field_name, :string, 1
        optional :index, :uint32, 2
      end
    end
    add_message "mdg.engine.proto.ReportHeader" do
      optional :graph_ref, :string, 12
      optional :hostname, :string, 5
      optional :agent_version, :string, 6
      optional :service_version, :string, 7
      optional :runtime_version, :string, 8
      optional :uname, :string, 9
      optional :executable_schema_id, :string, 11
    end
    add_message "mdg.engine.proto.PathErrorStats" do
      map :children, :string, :message, 1, "mdg.engine.proto.PathErrorStats"
      optional :errors_count, :uint64, 4
      optional :requests_with_errors_count, :uint64, 5
    end
    add_message "mdg.engine.proto.QueryLatencyStats" do
      repeated :latency_count, :sint64, 13
      optional :request_count, :uint64, 2
      optional :cache_hits, :uint64, 3
      optional :persisted_query_hits, :uint64, 4
      optional :persisted_query_misses, :uint64, 5
      repeated :cache_latency_count, :sint64, 14
      optional :root_error_stats, :message, 7, "mdg.engine.proto.PathErrorStats"
      optional :requests_with_errors_count, :uint64, 8
      repeated :public_cache_ttl_count, :sint64, 15
      repeated :private_cache_ttl_count, :sint64, 16
      optional :registered_operation_count, :uint64, 11
      optional :forbidden_operation_count, :uint64, 12
      optional :requests_without_field_instrumentation, :uint64, 17
    end
    add_message "mdg.engine.proto.StatsContext" do
      optional :client_name, :string, 2
      optional :client_version, :string, 3
    end
    add_message "mdg.engine.proto.ContextualizedQueryLatencyStats" do
      optional :query_latency_stats, :message, 1, "mdg.engine.proto.QueryLatencyStats"
      optional :context, :message, 2, "mdg.engine.proto.StatsContext"
    end
    add_message "mdg.engine.proto.ContextualizedTypeStats" do
      optional :context, :message, 1, "mdg.engine.proto.StatsContext"
      map :per_type_stat, :string, :message, 2, "mdg.engine.proto.TypeStat"
    end
    add_message "mdg.engine.proto.FieldStat" do
      optional :return_type, :string, 3
      optional :errors_count, :uint64, 4
      optional :observed_execution_count, :uint64, 5
      optional :estimated_execution_count, :uint64, 10
      optional :requests_with_errors_count, :uint64, 6
      repeated :latency_count, :sint64, 9
    end
    add_message "mdg.engine.proto.TypeStat" do
      map :per_field_stat, :string, :message, 3, "mdg.engine.proto.FieldStat"
    end
    add_message "mdg.engine.proto.ReferencedFieldsForType" do
      repeated :field_names, :string, 1
      optional :is_interface, :bool, 2
    end
    add_message "mdg.engine.proto.Report" do
      optional :header, :message, 1, "mdg.engine.proto.ReportHeader"
      map :traces_per_query, :string, :message, 5, "mdg.engine.proto.TracesAndStats"
      optional :end_time, :message, 2, "google.protobuf.Timestamp"
      optional :operation_count, :uint64, 6
    end
    add_message "mdg.engine.proto.ContextualizedStats" do
      optional :context, :message, 1, "mdg.engine.proto.StatsContext"
      optional :query_latency_stats, :message, 2, "mdg.engine.proto.QueryLatencyStats"
      map :per_type_stat, :string, :message, 3, "mdg.engine.proto.TypeStat"
    end
    add_message "mdg.engine.proto.TracesAndStats" do
      repeated :trace, :message, 1, "mdg.engine.proto.Trace"
      repeated :stats_with_context, :message, 2, "mdg.engine.proto.ContextualizedStats"
      map :referenced_fields_by_type, :string, :message, 4, "mdg.engine.proto.ReferencedFieldsForType"
      repeated :internal_traces_contributing_to_stats, :message, 3, "mdg.engine.proto.Trace"
    end
  end
end

module Mdg
  module Engine
    module Proto
      Trace = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace").msgclass
      Trace::CachePolicy = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.CachePolicy").msgclass
      Trace::CachePolicy::Scope = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.CachePolicy.Scope").enummodule
      Trace::Details = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.Details").msgclass
      Trace::Error = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.Error").msgclass
      Trace::HTTP = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.HTTP").msgclass
      Trace::HTTP::Values = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.HTTP.Values").msgclass
      Trace::HTTP::Method = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.HTTP.Method").enummodule
      Trace::Location = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.Location").msgclass
      Trace::Node = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.Node").msgclass
      Trace::QueryPlanNode = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.QueryPlanNode").msgclass
      Trace::QueryPlanNode::SequenceNode = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.QueryPlanNode.SequenceNode").msgclass
      Trace::QueryPlanNode::ParallelNode = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.QueryPlanNode.ParallelNode").msgclass
      Trace::QueryPlanNode::FetchNode = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.QueryPlanNode.FetchNode").msgclass
      Trace::QueryPlanNode::FlattenNode = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.QueryPlanNode.FlattenNode").msgclass
      Trace::QueryPlanNode::DeferNode = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.QueryPlanNode.DeferNode").msgclass
      Trace::QueryPlanNode::ConditionNode = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.QueryPlanNode.ConditionNode").msgclass
      Trace::QueryPlanNode::DeferNodePrimary = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.QueryPlanNode.DeferNodePrimary").msgclass
      Trace::QueryPlanNode::DeferredNode = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.QueryPlanNode.DeferredNode").msgclass
      Trace::QueryPlanNode::DeferredNodeDepends = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.QueryPlanNode.DeferredNodeDepends").msgclass
      Trace::QueryPlanNode::ResponsePathElement = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Trace.QueryPlanNode.ResponsePathElement").msgclass
      ReportHeader = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.ReportHeader").msgclass
      PathErrorStats = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.PathErrorStats").msgclass
      QueryLatencyStats = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.QueryLatencyStats").msgclass
      StatsContext = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.StatsContext").msgclass
      ContextualizedQueryLatencyStats = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.ContextualizedQueryLatencyStats").msgclass
      ContextualizedTypeStats = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.ContextualizedTypeStats").msgclass
      FieldStat = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.FieldStat").msgclass
      TypeStat = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.TypeStat").msgclass
      ReferencedFieldsForType = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.ReferencedFieldsForType").msgclass
      Report = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.Report").msgclass
      ContextualizedStats = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.ContextualizedStats").msgclass
      TracesAndStats = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("mdg.engine.proto.TracesAndStats").msgclass
    end
  end
end
