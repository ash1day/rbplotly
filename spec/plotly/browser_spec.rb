# frozen_string_literal: true

RSpec.describe Plotly::Browser do
  def command_on(host_os, path)
    stub_const("RbConfig::CONFIG", RbConfig::CONFIG.merge("host_os" => host_os))
    spawned = nil
    allow(Process).to receive(:spawn) { |*args, **|
      spawned = args
      0
    }
    allow(Process).to receive(:detach)
    described_class.open(path)
    spawned
  end

  it "opens files with the desktop's opener, passing the path as a single argument" do
    expect(command_on("darwin24", "/tmp/a b.html")).to eq(["open", "/tmp/a b.html"])
    expect(command_on("linux-gnu", "/tmp/a b.html")).to eq(["xdg-open", "/tmp/a b.html"])
  end

  it "does not go through cmd.exe on Windows, which would run commands hidden in the file name" do
    expect(command_on("mingw32", 'C:\\tmp\\a&calc.html')).to eq(["explorer.exe", 'C:\\tmp\\a&calc.html'])
  end

  it "prints the path instead of failing when no opener exists" do
    stub_const("RbConfig::CONFIG", RbConfig::CONFIG.merge("host_os" => "linux-gnu"))
    allow(Process).to receive(:spawn).and_raise(Errno::ENOENT)
    expect { described_class.open("/tmp/x.html") }.to output(%r{the chart is at /tmp/x.html}).to_stderr
  end
end
