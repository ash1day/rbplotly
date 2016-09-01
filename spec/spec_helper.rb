require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rbplotly'

TMP_DIR = File.dirname(__FILE__) + '/tmp/'

RSpec.configure do |config|
  config.after(:all) do
    FileUtils.rm_rf(Dir[TMP_DIR + '*.*'])
  end
end
