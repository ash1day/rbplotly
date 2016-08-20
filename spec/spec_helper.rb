$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rbplotly'

RSpec.configure do |config|
  config.after(:all) do
    FileUtils.rm_rf(Dir[File.dirname(__FILE__) + '/tmp/*.*'])
  end
end
