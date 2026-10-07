# frozen_string_literal: true

require "did_you_mean"

module Plotly
  # A plotly.js figure: traces (`data`), `layout`, `config` and animation `frames`.
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
    # @return [Array<Hash{String => Object}>] animation frames; direct mutation skips validation
    attr_reader :frames

    # @param data [Array<Hash>] traces; a trace without `type` is a scatter trace
    # @param layout [Hash]
    # @param config [Hash]
    # @param validate [Boolean] check attributes against the plotly.js schema
    # @param frames [Array<Hash>] partial trace/layout updates for animation
    def initialize(data: [], layout: {}, config: {}, validate: true, frames: [])
      @validate = validate
      @grid = nil
      @data = []
      @layout = build(schema.layout, layout, "layout")
      @config = build(schema.config, config, "config")
      raise ArgumentError, "data must be an Array of trace Hashes, got #{data.inspect}" unless data.is_a?(Array)

      data.each { |trace| add_trace(trace) }
      self.frames = frames
    end

    # Replaces the animation frames after validating all of them.
    # Define the base traces first so frames may omit their trace types.
    # @param frames [Array<Hash>]
    # @return [Array<Hash>]
    def frames=(frames)
      raise ValidationError, "frames: expected an Array of Hashes" unless frames.is_a?(Array)

      @frames = frames.each_with_index.map { |frame, i| build_frame(frame, i) }
    end

    # Appends a frame. `traces` maps its data entries to zero-based base trace indices.
    # @param frame [Hash] frame attributes, merged with keyword arguments
    # @return [self]
    def add_frame(frame = {}, **attrs)
      unless frame.is_a?(Hash)
        raise ValidationError, "frames[#{@frames.size}]: expected a Hash"
      end
      @frames << build_frame(frame.transform_keys(&:to_s).merge(attrs.transform_keys(&:to_s)), @frames.size)
      self
    end

    # Appends a trace.
    #
    # @param trace [Hash] trace attributes; keyword arguments are merged into it
    # @param row [Integer, nil] subplot row (1-based), for figures made by {Plotly.make_subplots}
    # @param col [Integer, nil] subplot column (1-based)
    # @param secondary_y [Boolean] use the cell's right y axis (requires row, col and a secondary_y spec)
    # @return [self]
    def add_trace(trace = {}, row: nil, col: nil, secondary_y: false, **attrs)
      check_secondary_y(secondary_y)
      trace = trace.to_h { |k, v| [k.to_s, v] }.merge(attrs.transform_keys(&:to_s))
      type = (trace.delete("type") || "scatter").to_s
      node = trace_node(type, "data[#{@data.size}]")
      built = {"type" => type}.merge(build(node, trace, "data[#{@data.size}]"))
      built.merge!(cell_reference(node, row, col, secondary_y)) if row || col || secondary_y
      @data << built
      self
    end

    Schema.default.trace_types.each do |type|
      # @!method add_scatter(row: nil, col: nil, secondary_y: false, **attrs)
      #   Appends a trace of this type; one such helper exists for every plotly.js trace type.
      #   @return [Figure]
      define_method(:"add_#{type}") do |trace = {}, row: nil, col: nil, secondary_y: false, **attrs|
        add_trace(trace.merge(attrs).merge(type: type), row: row, col: col, secondary_y: secondary_y)
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
    # @param secondary_y [Boolean, nil] select right/left y-axis traces; nil selects both
    # @return [self]
    def update_traces(attrs = {}, selector: nil, row: nil, col: nil, secondary_y: nil, **kw)
      check_secondary_y(secondary_y)
      grid! unless secondary_y.nil?
      attrs = attrs.merge(kw)
      targets = @data.each_index.select { |i| selected?(@data[i], selector) && in_cell?(@data[i], row, col, secondary_y) }
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
    # @param secondary_y [Boolean, nil] select right/left y axes; nil selects both
    # @return [self]
    def update_yaxes(attrs = {}, row: nil, col: nil, secondary_y: nil, **kw)
      check_secondary_y(secondary_y)
      update_axes("y", attrs.merge(kw), row, col, secondary_y)
    end

    # Renders the figure as HTML. See {HTML.render} for the options.
    #
    # @example In a Rails view
    #   <%= raw @figure.to_html(height: 400) %>
    # @return [String] an HTML fragment (or document with `full_html: true`)
    def to_html(include_plotlyjs: :cdn, full_html: false, div_id: nil, width: nil, height: nil,
      auto_play: true, animation_opts: {})
      HTML.render(self, include_plotlyjs: include_plotlyjs, full_html: full_html, div_id: div_id,
        width: width, height: height, auto_play: auto_play, animation_opts: animation_opts)
    end

    # Writes a standalone HTML page. By default plotly.js is embedded so the file works offline
    # and can be shared as a single attachment.
    #
    # @param path [String]
    # @param open [Boolean] also open the page in the default browser
    # @param auto_play [Boolean] start animation after the figure is drawn
    # @param animation_opts [Hash] options passed to Plotly.animate
    # @return [String] the path written
    def write_html(path, include_plotlyjs: :inline, open: false, width: nil, height: nil,
      auto_play: true, animation_opts: {})
      File.write(path, to_html(include_plotlyjs: include_plotlyjs, full_html: true, width: width, height: height,
        auto_play: auto_play, animation_opts: animation_opts))
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

    # IRuby's display hook. IRuby 0.8 prefers it to {#to_html}, whose output would run before
    # plotly.js loads in a notebook.
    # @return [Array(Hash{String => String}, Hash)] formats and metadata
    def to_iruby_mimebundle(include: [])
      [{"text/html" => HTML.notebook(self)}, {}]
    end

    # IRuby's display hook in versions before 0.8.
    # @return [Array(String, String)]
    def to_iruby = ["text/html", HTML.notebook(self)]

    # @return [Hash{String => Object}] data, layout and nonempty frames, sharing the
    #   figure's own Hashes: changing them skips validation, as with {#data} and {#layout}
    def to_h
      result = {"data" => @data, "layout" => @layout}
      result["frames"] = @frames unless @frames.empty?
      result
    end

    # @return [String] the figure as plotly.js JSON (config is not included, as in plotly.py)
    def to_json(*) = Serializer.dump(to_h)

    # @return [String] trace types and layout keys, without the data
    def inspect
      "#<#{self.class.name} data=[#{@data.map { |t| t["type"] }.join(", ")}] layout=[#{@layout.keys.join(", ")}]>"
    end

    # @api private
    # @param grid [Subplots::Grid] set by {Plotly.make_subplots}
    def subplot_grid=(grid)
      @grid = grid
    end

    private

    def schema = Schema.default

    def build_frame(frame, index)
      Frames.build(frame, data: @data, path: "frames[#{index}]", validate: @validate)
    end

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

    def check_secondary_y(value)
      raise ArgumentError, "secondary_y must be true, false or nil" unless [true, false, nil].include?(value)
    end

    def in_cell?(trace, row, col, secondary_y = nil)
      return true unless row || col || !secondary_y.nil?

      grid!.cells(row, col).any? do |cell|
        domain = trace["domain"]
        if domain.is_a?(Hash)
          secondary_y.nil? && domain["x"] == cell.x_domain && domain["y"] == cell.y_domain
        elsif schema.trace(trace["type"])&.child("xaxis")
          axes = [(trace["xaxis"] || "x").to_s, (trace["yaxis"] || "y").to_s]
          (secondary_y != true && cell.axis_ids == axes) ||
            (secondary_y != false && cell.secondary_index && cell.axis_ids(true) == axes)
        else
          false # 3D, polar, map... traces are not in any cell
        end
      end
    end

    def cell_reference(node, row, col, secondary_y)
      cell = grid!.cell(row, col)
      if secondary_y && (!node.child("xaxis") || !cell.secondary_index)
        raise ArgumentError, "secondary_y needs a cartesian trace and a cell with specs: {secondary_y: true}"
      end
      if node.child("xaxis")
        {"xaxis" => cell.axis_ids[0], "yaxis" => cell.axis_ids(secondary_y)[1]}
      elsif node.child("domain")
        {"domain" => {"x" => cell.x_domain, "y" => cell.y_domain}}
      else
        raise ArgumentError, "#{node.name} traces cannot be placed in a subplot cell"
      end
    end

    def update_axes(letter, attrs, row, col, secondary_y = nil)
      keys = if row || col || !secondary_y.nil?
        grid!.cells(row, col).flat_map { |cell| (letter == "y") ? cell.y_keys(secondary_y) : [cell.layout_key(letter)] }
      else
        # Traces on cartesian axes refer to x/y unless they name another axis.
        referenced = @data.filter_map do |t|
          next unless schema.trace(t["type"])&.child("#{letter}axis")

          (t["#{letter}axis"] || letter).to_s.sub(/\A#{letter}/, "#{letter}axis")
        end
        found = (@layout.keys.grep(/\A#{letter}axis\d*\z/) + referenced).uniq
        found.empty? ? ["#{letter}axis"] : found
      end
      update_layout(keys.to_h { |key| [key, attrs] })
    end

    def grid!
      @grid or raise ArgumentError, "row and col need a figure made by Plotly.make_subplots"
    end
  end
end
