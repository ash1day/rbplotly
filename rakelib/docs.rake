# frozen_string_literal: true

README_THUMBNAILS = %w[surface sankey geo distributions].freeze

# The figure built by the README's quick start, so its screenshot always matches the code.
def readme_quick_start_figure
  code = File.read("README.md")[/^## Quick start\n.*?^```ruby\n(.*?)^```/m, 1]
  scope = Object.new.instance_eval { binding }
  scope.eval(code.sub(/^fig\.write_html.*$/, ""), "README.md")
  scope.local_variable_get(:fig)
end

desc "Make the README's screenshots and hero GIF in docs/images/ (needs Chrome and ffmpeg)"
task "docs:images" => "plotlyjs:fetch" do
  require_relative "support/readme_media"

  FileUtils.mkdir_p("docs/images")
  examples = Gallery.examples.to_h { |ex| [ex.name, ex.figure] }
  Dir.mktmpdir do |dir|
    media = ReadmeMedia.new(dir)
    media.record_gif(examples.fetch("line"), "docs/images/hero.gif", width: 800, height: 460)
    puts "Wrote docs/images/hero.gif"
    media.screenshot(readme_quick_start_figure, "docs/images/quick-start.png", width: 800, height: 420)
    puts "Wrote docs/images/quick-start.png"
    README_THUMBNAILS.each do |name|
      media.screenshot(examples.fetch(name), "docs/images/#{name}.png", width: 900, height: 560)
      puts "Wrote docs/images/#{name}.png"
    end
  ensure
    media&.close
  end
end
