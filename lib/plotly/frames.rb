# frozen_string_literal: true

module Plotly
  # Normalizes animation frames and validates their partial trace and layout updates.
  # @api private
  module Frames
    module_function

    def build(frame, data:, path:, validate:)
      schema = Schema.default
      result = Attributes.build(schema.frame, frame, path: path, validate: validate)
      traces = result["traces"]
      if !traces.nil? && !(traces.is_a?(Array) && traces.all? { |i| i.is_a?(Integer) && i >= 0 })
        raise ValidationError, "#{path}.traces: expected an Array of non-negative trace indices"
      end
      unless result["data"].nil?
        unless result["data"].is_a?(Array) && result["data"].all?(Hash)
          raise ValidationError, "#{path}.data: expected an Array of Hashes"
        end
        result["data"] = result["data"].each_with_index.map do |trace, i|
          trace = trace.transform_keys(&:to_s)
          target = traces&.fetch(i, i) || i
          explicit_type = trace.delete("type")
          type = (explicit_type || data[target]&.fetch("type", nil) || "scatter").to_s
          node = schema.trace(type)
          raise ValidationError, "#{path}.data[#{i}].type: #{type.inspect} is not a plotly.js trace type" unless node

          attrs = Attributes.build(node, trace, path: "#{path}.data[#{i}]", validate: validate)
          explicit_type ? {"type" => type}.merge(attrs) : attrs
        end
      end
      unless result["layout"].nil?
        result["layout"] = Attributes.build(schema.layout, result["layout"], path: "#{path}.layout", validate: validate)
      end
      result
    end
  end
end
