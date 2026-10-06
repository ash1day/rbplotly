# frozen_string_literal: true

require "date"
require "did_you_mean" # explicit, so suggestions work under --disable-did_you_mean too

module Plotly
  # Turns user-supplied attribute hashes into plotly.js attribute trees.
  #
  # Keys become strings, underscore paths expand (`marker_line_width: 2` becomes
  # `{"marker" => {"line" => {"width" => 2}}}`) and, unless validation is off, every key and
  # value is checked against the schema. Values themselves are kept as given; converting them
  # to JSON is {Serializer}'s job.
  module Attributes
    module_function

    # @param node [Schema::Node] schema of the object being built
    # @param attrs [Hash]
    # @param path [String] location used in error messages, e.g. "data[0]" or "layout"
    # @param validate [Boolean]
    # @return [Hash{String => Object}]
    def build(node, attrs, path:, validate: true)
      Builder.new(validate).object(node, attrs, path)
    end

    # Merges two attribute trees built by {build}; nested hashes merge, everything else is replaced.
    def deep_merge(base, other)
      base.merge(other) do |_key, old, new|
        (old.is_a?(Hash) && new.is_a?(Hash)) ? deep_merge(old, new) : new
      end
    end

    # Walks one attribute hash against its schema node.
    # @api private
    class Builder
      def initialize(validate)
        @validate = validate
      end

      def object(node, attrs, path)
        unless attrs.is_a?(Hash)
          raise ValidationError, "#{path}: expected a Hash, got #{attrs.inspect}"
        end

        attrs.each_with_object({}) do |(key, value), result|
          key = key.to_s
          child = node&.child(key)
          if child.nil? && (expanded = expand(node, key, value))
            assign(result, expanded.first, object(node.child(expanded.first), expanded.last, join(path, expanded.first)))
          else
            unknown!(node, key, path) if child.nil? && node && @validate
            assign(result, key, value(child, value, join(path, key)))
          end
        end
      end

      private

      def join(path, key) = path.empty? ? key : "#{path}.#{key}"

      def assign(result, key, value)
        result[key] = (result[key].is_a?(Hash) && value.is_a?(Hash)) ? Attributes.deep_merge(result[key], value) : value
      end

      # "marker_line_width" => ["marker", {"line_width" => value}] when marker is an object.
      def expand(node, key, value)
        return nil unless node

        positions = (0...key.length).select { |i| key[i] == "_" }.reverse
        positions.each do |i|
          head = key[0...i]
          child = node.child(head)
          return [head, {key[(i + 1)..] => value}] if child&.object?
        end
        nil
      end

      def value(node, value, path)
        return value if node.nil?
        return object(node, value, path) if node.object? && value.is_a?(Hash)

        if node.object?
          invalid_object!(node, value, path) if @validate
          value
        elsif node.array?
          array(node, value, path)
        else
          leaf(node, value, path) if @validate
          value
        end
      end

      def array(node, value, path)
        unless value.is_a?(Array) && value.all?(Hash)
          return value unless @validate

          raise ValidationError, "#{path}: expected an Array of Hashes, got #{value.inspect}"
        end
        value.each_with_index.map { |item, i| object(node.item, item, "#{path}[#{i}]") }
      end

      def leaf(node, value, path)
        if node.array_ok? && array_like?(value)
          value.to_a.each_with_index { |v, i| scalar(node, v, "#{path}[#{i}]", path) }
        else
          scalar(node, value, path, path)
        end
      end

      def scalar(node, value, path, attr_path)
        return if value.nil?

        case node.type
        when "enumerated" then enumerated(node, value, path)
        when "flaglist" then flaglist(node, value, path, attr_path)
        when "boolean"
          invalid!(path, "expected true or false, got #{value.inspect}") unless [true, false].include?(value)
        when "number", "integer", "angle" then number(node, value, path)
        end
      end

      # Arrays, Ranges, Sets and data frame columns; Serializer writes all of them as arrays.
      def array_like?(value)
        case value
        when Array then true
        when String, Symbol, Hash, Numeric, Time, Date, true, false, nil then false
        else value.respond_to?(:to_a)
        end
      end

      def enumerated(node, value, path)
        given = value.is_a?(Symbol) ? value.to_s : value
        return if node.values.any? { |allowed| allowed_value?(allowed, given) }

        listed = node.values.reject { |v| pattern?(v) }
        message = "#{given.inspect} is not one of #{listed.map(&:inspect).join(", ")}"
        if given.is_a?(String)
          words = listed.grep(String)
          suggestion = DidYouMean::SpellChecker.new(dictionary: words).correct(given).first
          message += ". Did you mean #{suggestion.inspect}?" if suggestion
        end
        invalid!(path, message)
      end

      def allowed_value?(allowed, given)
        return Regexp.new(allowed[1..-2]).match?(given) if pattern?(allowed) && given.is_a?(String)

        allowed == given
      end

      def pattern?(value) = value.is_a?(String) && value.length > 1 && value.start_with?("/") && value.end_with?("/")

      def flaglist(node, value, path, attr_path)
        given = value.to_s
        return if node.extras.include?(given)

        name = attr_path.split(".").last
        given.split("+").each do |flag|
          next if node.flags.include?(flag)

          suggestion = DidYouMean::SpellChecker.new(dictionary: node.flags).correct(flag).first
          message = "#{flag.inspect} is not a flag of #{name}."
          message += " Did you mean #{suggestion.inspect}?" if suggestion
          message += " Join #{node.flags.map(&:inspect).join(", ")} with \"+\""
          message += case node.extras.size
          when 0 then ""
          when 1 then ", or use #{node.extras.first.inspect}"
          else ", or use one of #{node.extras.map(&:inspect).join(", ")}"
          end
          invalid!(path, message)
        end
      end

      # Follows plotly.js' coercion: named extras ("bold" for font.weight), numeric strings,
      # and whole floats for integers are accepted.
      def number(node, value, path)
        return if !value.is_a?(Numeric) && node.extras.include?(value.to_s)

        integer = node.type == "integer"
        number = case value
        when Complex then nil
        when Numeric then value
        when String then Float(value, exception: false)
        end
        ok = !number.nil? && (!integer || (number.finite? && number == number.round))
        invalid!(path, "expected #{integer ? "an integer" : "a number"}, got #{value.inspect}") unless ok

        invalid!(path, "#{value} is less than the minimum #{node.min}") if node.min && number < node.min
        invalid!(path, "#{value} is greater than the maximum #{node.max}") if node.max && number > node.max
      end

      def invalid_object!(node, value, path)
        hint = ""
        if value.is_a?(String) && node.attribute_names.include?("text")
          key = path.split(".").last
          underscored = path.split(".").drop(1).join("_")
          hint = ". Plotly.js no longer accepts a plain string here: use #{key}: {text: #{value.inspect}} " \
            "or #{underscored}_text: #{value.inspect}"
        end
        raise ValidationError, "#{path}: expected a Hash of #{node.name} attributes, got #{value.inspect}#{hint}"
      end

      def invalid!(path, message)
        raise ValidationError, "#{path}: #{message}"
      end

      def unknown!(node, key, path)
        message = "#{join(path, key)}: #{node.name} has no attribute #{key.inspect}"
        suggestion = DidYouMean::SpellChecker.new(dictionary: node.attribute_names).correct(key).first
        message += ". Did you mean #{suggestion.inspect}?" if suggestion
        raise ValidationError, message
      end
    end
  end
end
