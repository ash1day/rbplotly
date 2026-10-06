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
  # @param figure_options [Hash] passed to {Figure#initialize} (`layout:`, `config:`, `validate:`)
  # @return [Figure]
  def self.make_subplots(rows: 1, cols: 1, shared_xaxes: false, shared_yaxes: false, subplot_titles: nil,
    horizontal_spacing: 0.2 / cols, vertical_spacing: 0.3 / rows, **figure_options)
    grid = Subplots::Grid.new(rows, cols, horizontal_spacing, vertical_spacing)
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
    Cell = Struct.new(:row, :col, :index, :x_domain, :y_domain) do
      def suffix = (index == 1) ? "" : index.to_s

      def axis_ids = ["x#{suffix}", "y#{suffix}"]

      def layout_key(letter) = "#{letter}axis#{suffix}"
    end

    class Grid
      attr_reader :rows, :cols

      def initialize(rows, cols, horizontal_spacing, vertical_spacing)
        unless rows.is_a?(Integer) && cols.is_a?(Integer) && rows.positive? && cols.positive?
          raise ArgumentError, "rows and cols must be positive integers"
        end

        @rows = rows
        @cols = cols
        width = (1.0 - horizontal_spacing * (cols - 1)) / cols
        height = (1.0 - vertical_spacing * (rows - 1)) / rows
        raise ArgumentError, "spacing leaves no room for the subplots" unless width.positive? && height.positive?

        @cells = (1..rows).flat_map do |row|
          (1..cols).map do |col|
            x0 = (col - 1) * (width + horizontal_spacing)
            y1 = 1.0 - (row - 1) * (height + vertical_spacing)
            Cell.new(row, col, (row - 1) * cols + col, domain(x0, x0 + width), domain(y1 - height, y1))
          end
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

      # Follows another axis' range and leaves the tick labels to it.
      def linked(axis_id) = {"matches" => axis_id, "showticklabels" => false}

      def domain(from, to) = [from.round(12).clamp(0.0, 1.0), to.round(12).clamp(0.0, 1.0)]
    end
  end
end
