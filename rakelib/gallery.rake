# frozen_string_literal: true

desc "Build the example gallery into site/ (published to GitHub Pages)"
task :gallery do
  require_relative "support/gallery"
  list = Gallery.build("site")
  puts "Wrote site/index.html with #{list.size} examples"
end
