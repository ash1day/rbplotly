# frozen_string_literal: true

require "date"
require "json"

module Plotly
  # Writes figures as the JSON that plotly.js reads.
  module Serializer
    module_function

    # Characters escaped in JSON so it can be embedded in HTML.
    HTML_UNSAFE = {"<" => "\\u003c", ">" => "\\u003e", "&" => "\\u0026"}.freeze

    # @return [String] JSON that is safe to place inside an HTML <script> element: `<`, `>`
    #   and `&` (which only occur inside strings) and U+2028/2029 are written as escapes
    def dump(value)
      JSON.generate(plain(value), script_safe: true).gsub(/[<>&]/, HTML_UNSAFE)
    end

    # Converts a value into Hashes, Arrays, Strings, numbers, booleans and nils.
    def plain(value)
      case value
      when Hash then value.to_h { |k, v| [k.to_s, plain(v)] }
      when Array then value.map { |v| plain(v) }
      when String, Integer, true, false, nil then value
      when Symbol then value.to_s
      when Float then value.finite? ? value : nil
      when Complex then unsupported!(value)
      when Numeric then plain(value.to_f)
      when Time, DateTime then timestamp(value)
      when Date then value.strftime("%Y-%m-%d")
      else
        # Ranges, Sets, Enumerators and data frame columns (Numo::NArray, Polars::Series, ...)
        value.respond_to?(:to_a) ? plain(value.to_a) : unsupported!(value)
      end
    end

    # plotly.js has no time zones: a date string is drawn as the wall-clock time it names.
    def timestamp(time)
      fraction = time.strftime("%N").sub(/0+\z/, "")
      time.strftime("%Y-%m-%d %H:%M:%S") + (fraction.empty? ? "" : ".#{fraction}")
    end

    def unsupported!(value)
      raise TypeError, "#{value.inspect} (#{value.class}) cannot be written as plotly.js JSON"
    end
  end
end
