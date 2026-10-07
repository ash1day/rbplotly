# frozen_string_literal: true

module Plotly
  # Builds a figure with a grid of subplots, each with its own x and y axis.
  #
  # Cells are numbered from the top-left, row by row; traces are placed with
  # `add_trace(..., row:, col:)`. Spacing defaults follow plotly.py.
  #
  # @example
  #   fig = Plotly.make_subplots(rows: 1, cols: 2, subplot_titles: ["Revenue", "Users"])
  #   fig.add_bar(x: months, y: revenue, row: 1, col: 1)
  #   fig.add_scatter(x: months, y: users, row: 1, col: 2)
  #
  # @param rows [Integer]
  # @param cols [Integer]
  # @param shared_xaxes [Boolean] link the x axes of each column and label only the bottom one
  # @param shared_yaxes [Boolean] link the y axes of each row and label only the left one
  # @param subplot_titles [Array<String>, nil] one title per cell, in row-major order
  # @param horizontal_spacing [Float] gap between columns, as a fraction of the figure width
  # @param vertical_spacing [Float] gap between rows, as a fraction of the figure height
  # @param column_widths [Array<Numeric>, nil] positive relative column widths, left to right
  # @param row_heights [Array<Numeric>, nil] positive relative row heights, top to bottom
  # @param specs [Array<Array<Hash>>, nil] one hash per cell; `secondary_y: true` adds a right y axis
  # @param figure_options [Hash] passed to {Figure#initialize} (`layout:`, `config:`, `validate:`)
  # @return [Figure]
  def self.make_subplots(rows: 1, cols: 1, shared_xaxes: false, shared_yaxes: false, subplot_titles: nil,
    horizontal_spacing: nil, vertical_spacing: nil, column_widths: nil, row_heights: nil, specs: nil, **figure_options)
    grid = Subplots::Grid.new(rows, cols, horizontal_spacing, vertical_spacing,
      column_widths: column_widths, row_heights: row_heights, specs: specs)
    titles = Array(subplot_titles)
    if titles.size > grid.cells.size
      raise ArgumentError, "#{titles.size} subplot titles for #{grid.cells.size} cells"
    end

    figure = Figure.new(**figure_options)
    figure.subplot_grid = grid
    figure.update_layout(grid.axes_layout(shared_xaxes, shared_yaxes))
    annotations = grid.title_annotations(titles)
    figure.update_layout(annotations: (figure.layout["annotations"] || []) + annotations) if annotations.any?
    figure
  end

  # Grid layout behind {Plotly.make_subplots}.
  # @api private
  module Subplots
    Cell = Struct.new(:row, :col, :index, :x_domain, :y_domain, :secondary_index) do
      def suffix = (index == 1) ? "" : index.to_s

      def axis_ids(secondary_y = false) = ["x#{suffix}", secondary_y ? "y#{secondary_index}" : "y#{suffix}"]

      def layout_key(letter) = "#{letter}axis#{suffix}"

      def y_keys(secondary_y = nil)
        keys = []
        keys << layout_key("y") unless secondary_y == true
        keys << "yaxis#{secondary_index}" if secondary_index && secondary_y != false
        keys
      end
    end

    class Grid
      attr_reader :rows, :cols

      def initialize(rows, cols, horizontal_spacing, vertical_spacing, column_widths: nil, row_heights: nil, specs: nil)
        unless rows.is_a?(Integer) && cols.is_a?(Integer) && rows.positive? && cols.positive?
          raise ArgumentError, "rows and cols must be positive integers"
        end

        @rows = rows
        @cols = cols
        horizontal_spacing = 0.2 / cols if horizontal_spacing.nil?
        vertical_spacing = 0.3 / rows if vertical_spacing.nil?
        horizontal_spacing = spacing(horizontal_spacing, cols, "horizontal_spacing")
        vertical_spacing = spacing(vertical_spacing, rows, "vertical_spacing")
        widths = sizes(column_widths, cols, 1.0 - horizontal_spacing * (cols - 1), "column_widths")
        heights = sizes(row_heights, rows, 1.0 - vertical_spacing * (rows - 1), "row_heights")
        secondary = secondary_cells(specs)
        next_axis = rows * cols

        y1 = 1.0
        @cells = (1..rows).flat_map do |row|
          x0 = 0.0
          cells = (1..cols).map do |col|
            second_axis = secondary[row - 1][col - 1] ? (next_axis += 1) : nil
            cell = Cell.new(row, col, (row - 1) * cols + col,
              domain(x0, x0 + widths[col - 1]), domain(y1 - heights[row - 1], y1), second_axis)
            x0 += widths[col - 1] + horizontal_spacing
            cell
          end
          y1 -= heights[row - 1] + vertical_spacing
          cells
        end
      end

      # @return [Array<Cell>] every cell, or the cells in the given row and/or column
      def cells(row = nil, col = nil)
        @cells.select { |c| (row.nil? || c.row == row) && (col.nil? || c.col == col) }
      end

      def cell(row, col)
        found = cells(row, col)
        return found.first if row && col && found.size == 1

        raise ArgumentError, "row #{row.inspect}, col #{col.inspect} is outside the #{rows}x#{cols} subplot grid"
      end

      def axes_layout(shared_x, shared_y)
        @cells.each_with_object({}) do |cell, layout|
          x_id, y_id = cell.axis_ids
          layout[cell.layout_key("x")] = {"domain" => cell.x_domain, "anchor" => y_id}.merge(
            (shared_x && cell.row != rows) ? linked(cell(rows, cell.col).axis_ids[0]) : {}
          )
          layout[cell.layout_key("y")] = {"domain" => cell.y_domain, "anchor" => x_id}.merge(
            (shared_y && cell.col != 1) ? linked(cell(cell.row, 1).axis_ids[1]) : {}
          )
          if cell.secondary_index
            layout["yaxis#{cell.secondary_index}"] = {"anchor" => x_id, "overlaying" => y_id,
              "side" => "right", "automargin" => true}
          end
        end
      end

      def title_annotations(titles)
        titles.each_with_index.filter_map do |title, i|
          next if title.nil? || title.to_s.empty?

          cell = @cells[i]
          {
            "text" => title, "showarrow" => false, "font" => {"size" => 16},
            "xref" => "paper", "yref" => "paper", "xanchor" => "center", "yanchor" => "bottom",
            "x" => ((cell.x_domain[0] + cell.x_domain[1]) / 2).round(12), "y" => cell.y_domain[1]
          }
        end
      end

      private

      def positive_number?(value)
        value.is_a?(Numeric) && !value.is_a?(Complex) && value.finite? && value.positive?
      end

      def spacing(value, count, name)
        unless value.is_a?(Numeric) && !value.is_a?(Complex) && value.finite? && value.between?(0, 1)
          raise ArgumentError, "#{name} must be a finite number between 0 and 1"
        end
        raise ArgumentError, "spacing leaves no room for the subplots" unless value * (count - 1) < 1

        value.to_f
      end

      def sizes(values, count, available, name)
        values = Array.new(count, 1) if values.nil?
        unless values.is_a?(Array) && values.size == count && values.all? { |v| positive_number?(v) }
          raise ArgumentError, "#{name} must contain #{count} positive finite numbers"
        end
        largest = values.max
        weights = values.map { |v| v.fdiv(largest) }
        total = weights.sum
        weights.map { |v| available * v / total }
      end

      def secondary_cells(specs)
        return Array.new(rows) { Array.new(cols, false) } if specs.nil?
        unless specs.is_a?(Array) && specs.size == rows && specs.all? { |row| row.is_a?(Array) && row.size == cols }
          raise ArgumentError, "specs must be a #{rows}x#{cols} array of cell hashes"
        end
        specs.map do |row|
          row.map do |spec|
            unless spec.is_a?(Hash) && spec.keys.all? { |k| k.to_s == "secondary_y" }
              raise ArgumentError, "each spec must be a Hash with only the secondary_y option"
            end
            value = spec.transform_keys(&:to_s).fetch("secondary_y", false)
            raise ArgumentError, "secondary_y must be true or false" unless [true, false].include?(value)

            value
          end
        end
      end

      # Follows another axis' range and leaves the tick labels to it.
      def linked(axis_id) = {"matches" => axis_id, "showticklabels" => false}

      def domain(from, to) = [from.round(12).clamp(0.0, 1.0), to.round(12).clamp(0.0, 1.0)]
    end
  end
end
