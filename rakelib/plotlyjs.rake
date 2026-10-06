# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "net/http"
require_relative "../lib/plotly/version"
require_relative "support/schema_pruner"

PLOTLY_JS_URL = "https://cdn.plot.ly/plotly-#{Plotly::PLOTLY_JS_VERSION}.min.js"
PLOT_SCHEMA_URL = "https://raw.githubusercontent.com/plotly/plotly.js/v#{Plotly::PLOTLY_JS_VERSION}/dist/plot-schema.json"
# Update together with Plotly::PLOTLY_JS_VERSION (`rake plotlyjs:checksum` prints it).
PLOTLY_JS_SHA256 = "2f645d1bade8182fce161b7f10f89402f8b315805250ff4a94672a28d23c390a"
PLOTLY_JS_PATH = "lib/plotly/assets/plotly.min.js"
SCHEMA_PATH = "lib/plotly/schema/plot-schema.json"

def download(url)
  uri = URI(url)
  response = Net::HTTP.get_response(uri)
  raise "GET #{url} failed: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

  response.body
end

def pruned_schema_json
  pruned = SchemaPruner.new(JSON.parse(download(PLOT_SCHEMA_URL))).call
  JSON.pretty_generate({"plotly_js" => Plotly::PLOTLY_JS_VERSION}.merge(pruned)) + "\n"
end

namespace :plotlyjs do
  desc "Download the pinned plotly.js bundle into #{PLOTLY_JS_PATH} and verify its checksum"
  task :fetch do
    next if File.exist?(PLOTLY_JS_PATH) && Digest::SHA256.file(PLOTLY_JS_PATH).hexdigest == PLOTLY_JS_SHA256

    body = download(PLOTLY_JS_URL)
    actual = Digest::SHA256.hexdigest(body)
    raise "plotly.js checksum mismatch: expected #{PLOTLY_JS_SHA256}, got #{actual}" unless actual == PLOTLY_JS_SHA256

    FileUtils.mkdir_p(File.dirname(PLOTLY_JS_PATH)) # its only file is gitignored, so a fresh clone lacks it
    File.binwrite(PLOTLY_JS_PATH, body)
    puts "Wrote #{PLOTLY_JS_PATH} (plotly.js #{Plotly::PLOTLY_JS_VERSION})"
  end

  desc "Print the SHA-256 of the plotly.js bundle for Plotly::PLOTLY_JS_VERSION"
  task :checksum do
    puts Digest::SHA256.hexdigest(download(PLOTLY_JS_URL))
  end
end

namespace :schema do
  desc "Regenerate #{SCHEMA_PATH} from plotly.js' plot-schema.json"
  task :generate do
    File.write(SCHEMA_PATH, pruned_schema_json)
    puts "Wrote #{SCHEMA_PATH} (plotly.js #{Plotly::PLOTLY_JS_VERSION})"
  end

  desc "Validate plotly.js' test mocks (MOCKS=path/to/test/image/mocks) and list what is rejected"
  task :mocks do
    require_relative "support/mock_sweep"
    dir = ENV.fetch("MOCKS") { abort "Set MOCKS to plotly.js' test/image/mocks for v#{Plotly::PLOTLY_JS_VERSION}" }
    total, rejected = MockSweep.run(dir)
    puts "#{total - rejected.values.sum(&:size)} of #{total} mocks pass validation"
    rejected.sort_by { |_, files| -files.size }.each { |reason, files| puts format("%4d  %s", files.size, reason) }
  end

  desc "Fail if #{SCHEMA_PATH} is not what `rake schema:generate` would write"
  task :check do
    next if File.read(SCHEMA_PATH) == pruned_schema_json

    abort "#{SCHEMA_PATH} is stale. Run `rake schema:generate` and commit the result."
  end
end
