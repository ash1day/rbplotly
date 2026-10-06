# frozen_string_literal: true

# Runs the Ruby examples in README.md, in order and sharing local variables, so the README
# cannot drift from the code. A line followed by `# => Plotly::ValidationError: message`
# (continued on `#    ` lines) must raise exactly that error.
RSpec.describe "README.md" do
  readme = File.read(File.expand_path("../README.md", __dir__))
  blocks = readme.scan(/^```ruby\n(.*?)^```/m).flatten

  it "has Ruby examples" do
    expect(blocks.size).to be >= 5
  end

  it "runs every Ruby example as documented" do
    scope = Object.new.instance_eval { binding }
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        blocks.each do |block|
          lines = block.lines
          until lines.empty?
            line = lines.shift
            next if line.strip.empty? || line.strip.start_with?("#")

            if lines.first&.start_with?("# => Plotly::ValidationError: ")
              message = lines.shift.delete_prefix("# => Plotly::ValidationError: ").strip
              message += " " + lines.shift.delete_prefix("#").strip while lines.first&.start_with?("#    ")
              expect { scope.eval(line) }.to raise_error(Plotly::ValidationError, message)
            else
              statement = line
              statement += lines.shift until lines.empty? || (complete?(statement) && !lines.first.lstrip.start_with?("."))
              scope.eval(statement)
            end
          end
        end
        expect(File).to exist("sales.html")
      end
    end
  end

  def complete?(code)
    RubyVM::InstructionSequence.compile(code)
    true
  rescue SyntaxError
    false
  end
end
