# frozen_string_literal: true

# Reduces plotly.js' dist/plot-schema.json (~4 MB of docs and editor metadata) to the parts
# rbplotly validates against: attribute names, nesting, value types and allowed values.
class SchemaPruner
  META_KEYS = %w[description editType impliedEdits role _isSubplotObj _isLinkedToArray
    _arrayAttrRegexps _deprecated items].freeze
  LEAF_KEYS = {
    "values" => "values", "flags" => "flags", "extras" => "extras",
    "arrayOk" => "array_ok", "min" => "min", "max" => "max"
  }.freeze

  def initialize(schema)
    @schema = schema
  end

  def call
    traces = @schema.fetch("traces").sort.to_h do |type, trace|
      [type, prune_object(trace.fetch("attributes"))]
    end

    layout = prune_object(@schema.fetch("layout").fetch("layoutAttributes"))
    # Trace modules contribute layout attributes (bar adds barmode, scatter adds scattermode...).
    # Those of traces drawn on a subplot type (barpolar on polar) belong to that subplot.
    @schema.fetch("traces").each_value do |trace|
      subplot = (trace["categories"] || []).find { |c| layout["attrs"].dig(c, "subplot") }
      target = subplot ? layout["attrs"][subplot] : layout
      (trace["layoutAttributes"] || {}).each do |name, attr|
        target["attrs"][name] ||= prune(attr)
      end
      target["attrs"] = target["attrs"].sort.to_h
    end

    {
      "traces" => traces,
      "layout" => layout,
      "config" => prune_object(@schema.fetch("config")),
      "frames" => prune(@schema.fetch("frames"))
    }
  end

  private

  def prune(attr)
    if attr.key?("valType")
      prune_leaf(attr)
    elsif attr.key?("items")
      item = attr.fetch("items").values.first
      {"array" => prune_object(item)}
    else
      prune_object(attr)
    end
  end

  def prune_leaf(attr)
    leaf = {"type" => attr.fetch("valType")}
    LEAF_KEYS.each { |from, to| leaf[to] = attr[from] if attr.key?(from) }
    leaf
  end

  def prune_object(obj)
    attrs = obj.each_with_object({}) do |(name, value), acc|
      next if META_KEYS.include?(name) || !value.is_a?(Hash)

      acc[name] = prune(value)
    end
    node = {"attrs" => attrs.sort.to_h}
    node["subplot"] = true if obj["_isSubplotObj"]
    node
  end
end
