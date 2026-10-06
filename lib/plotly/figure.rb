# frozen_string_literal: true

module Plotly
  # A plotly.js figure: traces (`data`), `layout` and `config`.
  #
  # Every attribute is checked against the schema of the bundled plotly.js release when it
  # is added, so a typo fails where it was written instead of silently drawing nothing.
  #
  # @example
  #   fig = Plotly::Figure.new
  #     .add_scatter(x: [1, 2, 3], y: [2, 1, 3], mode: :lines, name: "Model")
  #     .update_layout(title_text: "Forecast", xaxis_title_text: "Day")
  #   fig.write_html("forecast.html")
  class Figure
    # @return [Array<Hash{String => Object}>] traces, normalized. Changing them directly skips validation.
    attr_reader :data
    # @return [Hash{String => Object}] the layout, normalized. Changing it directly skips validation.
    attr_reader :layout
    # @return [Hash{String => Object}] plotly.js config (modebar, responsiveness, ...)
    attr_reader :config

    # @param data [Array<Hash>] traces; a trace without `type` is a scatter trace
    # @param layout [Hash]
    # @param config [Hash]
    # @param validate [Boolean] check attributes against the plotly.js schema
    def initialize(data: [], layout: {}, config: {}, validate: true)
      @validate = validate
      @grid = nil
      @data = []
      @layout = build(schema.layout, layout, "layout")
      @config = build(schema.config, config, "config")
      data.each { |trace| add_trace(trace) }
    end

    # Appends a trace.
    #
    # @param trace [Hash] trace attributes; keyword arguments are merged into it
    # @param row [Integer, nil] subplot row (1-based), for figures made by {Plotly.make_subplots}
    # @param col [Integer, nil] subplot column (1-based)
    # @return [self]
    def add_trace(trace = {}, row: nil, col: nil, **attrs)
      trace = trace.to_h { |k, v| [k.to_s, v] }.merge(attrs.transform_keys(&:to_s))
      type = (trace.delete("type") || "scatter").to_s
      node = trace_node(type, "data[#{@data.size}]")
      built = {"type" => type}.merge(build(node, trace, "data[#{@data.size}]"))
      built.merge!(cell_reference(node, row, col)) if row || col
      @data << built
      self
    end

    Schema.default.trace_types.each do |type|
      # @!method add_scatter(row: nil, col: nil, **attrs)
      #   Appends a trace of this type; one such helper exists for every plotly.js trace type.
      #   @return [Figure]
      define_method(:"add_#{type}") do |trace = {}, row: nil, col: nil, **attrs|
        add_trace(trace.merge(attrs).merge(type: type), row: row, col: col)
      end
    end

    # Deep-merges attributes into the layout. Nothing changes if any attribute is invalid.
    # @return [self]
    def update_layout(attrs = {}, **kw)
      @layout = Attributes.deep_merge(@layout, build(schema.layout, attrs.merge(kw), "layout"))
      self
    end

    # Deep-merges attributes into the config.
    # @return [self]
    def update_config(attrs = {}, **kw)
      @config = Attributes.deep_merge(@config, build(schema.config, attrs.merge(kw), "config"))
      self
    end

    # Deep-merges attributes into every trace, or into the traces that match.
    #
    # @param selector [Hash, Proc, nil] attributes a trace must have (`{type: :bar}`), or a
    #   block receiving the normalized trace
    # @param row [Integer, nil] only traces in this subplot row
    # @param col [Integer, nil] only traces in this subplot column
    # @return [self]
    def update_traces(attrs = {}, selector: nil, row: nil, col: nil, **kw)
      attrs = attrs.merge(kw)
      targets = @data.each_index.select { |i| selected?(@data[i], selector) && in_cell?(@data[i], row, col) }
      updates = targets.to_h do |i|
        [i, build(trace_node(@data[i]["type"], "data[#{i}]"), attrs, "data[#{i}]")]
      end
      updates.each { |i, update| @data[i] = Attributes.deep_merge(@data[i], update) }
      self
    end

    # Deep-merges attributes into every x axis, or into the x axis of one subplot.
    # @return [self]
    def update_xaxes(attrs = {}, row: nil, col: nil, **kw) = update_axes("x", attrs.merge(kw), row, col)

    # Deep-merges attributes into every y axis, or into the y axis of one subplot.
    # @return [self]
    def update_yaxes(attrs = {}, row: nil, col: nil, **kw) = update_axes("y", attrs.merge(kw), row, col)

    # Renders the figure as HTML. See {HTML.render} for the options.
    #
    # @example In a Rails view
    #   <%= raw @figure.to_html(height: 400) %>
    # @return [String] an HTML fragment (or document with `full_html: true`)
    def to_html(include_plotlyjs: :cdn, full_html: false, div_id: nil, width: nil, height: nil)
      HTML.render(self, include_plotlyjs: include_plotlyjs, full_html: full_html, div_id: div_id,
        width: width, height: height)
    end

    # Writes a standalone HTML page. By default plotly.js is embedded so the file works offline
    # and can be shared as a single attachment.
    #
    # @param path [String]
    # @param open [Boolean] also open the page in the default browser
    # @return [String] the path written
    def write_html(path, include_plotlyjs: :inline, open: false, width: nil, height: nil)
      File.write(path, to_html(include_plotlyjs: include_plotlyjs, full_html: true, width: width, height: height))
      Browser.open(File.expand_path(path)) if open
      path
    end

    # Shows the figure: inline in an IRuby notebook, otherwise as a temporary page in the browser.
    # @return [String, nil] the temporary file outside notebooks
    def show
      if defined?(::IRuby) && ::IRuby.respond_to?(:display)
        ::IRuby.display(self)
        return nil
      end

      write_html(File.join(Dir.tmpdir, "rbplotly-#{SecureRandom.hex(8)}.html"), open: true)
    end

    # IRuby's rich display hook.
    # @return [Array(String, String)]
    def to_iruby = ["text/html", HTML.notebook(self)]

    # @return [Hash{String => Object}] `{"data" => [...], "layout" => {...}}`
    def to_h = {"data" => @data, "layout" => @layout}

    # @return [String] the figure as plotly.js JSON (config is not included, as in plotly.py)
    def to_json(*) = Serializer.dump(to_h)

    def inspect
      "#<#{self.class.name} data=[#{@data.map { |t| t["type"] }.join(", ")}] layout=[#{@layout.keys.join(", ")}]>"
    end

    # @api private
    def subplot_grid=(grid)
      @grid = grid
    end

    private

    def schema = Schema.default

    def build(node, attrs, path) = Attributes.build(node, attrs, path: path, validate: @validate)

    def trace_node(type, path)
      node = schema.trace(type)
      return node if node

      message = "#{path}.type: #{type.inspect} is not a plotly.js trace type"
      suggestion = DidYouMean::SpellChecker.new(dictionary: schema.trace_types).correct(type).first
      raise ValidationError, suggestion ? "#{message}. Did you mean #{suggestion.inspect}?" : message
    end

    def selected?(trace, selector)
      case selector
      when nil then true
      when Proc then selector.call(trace)
      when Hash
        selector.all? { |key, value| Serializer.plain(trace[key.to_s]) == Serializer.plain(value) }
      else raise ArgumentError, "selector must be a Hash or a Proc, got #{selector.inspect}"
      end
    end

    def in_cell?(trace, row, col)
      return true unless row || col

      grid!.cells(row, col).any? { |cell| cell.axis_ids == [trace["xaxis"] || "x", trace["yaxis"] || "y"] }
    end

    def cell_reference(node, row, col)
      cell = grid!.cell(row, col)
      if node.child("xaxis")
        {"xaxis" => cell.axis_ids[0], "yaxis" => cell.axis_ids[1]}
      elsif node.child("domain")
        {"domain" => {"x" => cell.x_domain, "y" => cell.y_domain}}
      else
        raise ArgumentError, "#{node.name} traces cannot be placed in a subplot cell"
      end
    end

    def update_axes(letter, attrs, row, col)
      keys = if row || col
        grid!.cells(row, col).map { |cell| cell.layout_key(letter) }
      else
        found = @layout.keys.grep(/\A#{letter}axis\d*\z/)
        found.empty? ? ["#{letter}axis"] : found
      end
      update_layout(keys.to_h { |key| [key, attrs] })
    end

    def grid!
      @grid or raise ArgumentError, "row and col need a figure made by Plotly.make_subplots"
    end
  end
end
