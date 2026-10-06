# frozen_string_literal: true

README_IMAGES = %w[subplots line distributions surface].freeze

desc "Screenshot examples for the README into docs/images/ (needs Chrome)"
task "docs:images" => "plotlyjs:fetch" do
  require "ferrum"
  require "fileutils"
  require_relative "support/gallery"

  FileUtils.mkdir_p("docs/images")
  examples = Gallery.examples.select { |ex| README_IMAGES.include?(ex.name) }
  browser = Ferrum::Browser.new(headless: true, timeout: 60, window_size: [1000, 800])
  Dir.mktmpdir do |dir|
    examples.each do |ex|
      path = ex.figure.update_layout(width: 900, height: 560)
        .write_html(File.join(dir, "#{ex.name}.html"), width: 900, height: 560)
      browser.go_to("file://#{path}")
      sleep 0.1 until browser.evaluate("!!document.querySelector('.plotly-graph-div .main-svg')")
      sleep 1 # let WebGL traces (surface) finish their first frame
      browser.screenshot(path: "docs/images/#{ex.name}.png", selector: ".plotly-graph-div")
      puts "Wrote docs/images/#{ex.name}.png"
    end
  end
ensure
  browser&.quit
end
