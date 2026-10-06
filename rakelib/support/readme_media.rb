# frozen_string_literal: true

require "ferrum"
require "fileutils"
require "tmpdir"
require_relative "gallery"

# Renders figures in headless Chrome to make the README's screenshots and its hero GIF.
class ReadmeMedia
  CURSOR = <<~JS
    var c = document.createElement("div");
    c.id = "fake-cursor";
    c.innerHTML = '<svg width="20" height="20" viewBox="0 0 20 20"><path d="M2 2 L2 16 L6 12 L9 18 L11 17 L8 11 L14 11 Z" fill="#111" stroke="#fff" stroke-width="1.2"/></svg>';
    c.style.cssText = "position:fixed;left:0;top:0;pointer-events:none;z-index:99999;display:none";
    document.body.appendChild(c);
    document.addEventListener("mousemove", function (e) {
      c.style.display = "block";
      c.style.transform = "translate(" + (e.clientX - 2) + "px," + (e.clientY - 2) + "px)";
    }, true);
  JS

  def initialize(dir)
    @dir = dir
    @browser = Ferrum::Browser.new(headless: true, timeout: 60, window_size: [1000, 800])
  end

  def close = @browser.quit

  # Screenshots a figure at the given size.
  def screenshot(figure, path, width:, height:)
    load(figure, width, height)
    @browser.screenshot(path: path, selector: ".plotly-graph-div")
  end

  # Records hovering along a line chart, box-zooming into it and double-clicking back out.
  def record_gif(figure, path, width:, height:)
    load(figure, width, height)
    @browser.execute(CURSOR)
    size = @browser.evaluate("document.querySelector('.plotly-graph-div')._fullLayout._size")
    left, top, w, h = size.values_at("l", "t", "w", "h")
    frames = []
    snap = -> { frames << shoot(frames.size) }
    mouse = @browser.mouse

    mouse.move(x: left + 10, y: top + h * 0.5)
    36.times do |i|
      mouse.move(x: left + 10 + (w - 20) * i / 35.0, y: top + h * (0.5 - 0.15 * Math.sin(i / 6.0)))
      snap.call
    end
    4.times { snap.call }

    from = [left + w * 0.55, top + 12]
    to = [left + w * 0.82, top + h - 12]
    mouse.move(x: from[0], y: from[1])
    mouse.down
    14.times do |i|
      t = (i + 1) / 14.0
      mouse.move(x: from[0] + (to[0] - from[0]) * t, y: from[1] + (to[1] - from[1]) * t)
      snap.call
    end
    mouse.up
    8.times { snap.call && sleep(0.05) }

    18.times do |i|
      mouse.move(x: left + w * (0.2 + 0.6 * i / 17.0), y: top + h * 0.4)
      snap.call
    end

    mouse.click(x: left + w * 0.5, y: top + h * 0.5, count: 2)
    10.times { snap.call && sleep(0.05) }
    6.times { snap.call }

    encode(frames, path)
  end

  private

  def load(figure, width, height)
    page = figure.write_html(File.join(@dir, "figure-#{rand(1 << 30)}.html"), width: width, height: height)
    @browser.go_to("file://#{page}")
    sleep 0.1 until @browser.evaluate("!!document.querySelector('.plotly-graph-div .main-svg')")
    sleep 1 # let WebGL traces (surface) finish their first frame
  end

  def shoot(index)
    path = File.join(@dir, format("frame%03d.png", index))
    @browser.screenshot(path: path, selector: ".plotly-graph-div")
    path
  end

  def encode(frames, path)
    pattern = File.join(@dir, "frame%03d.png")
    filters = "fps=12,split[a][b];[a]palettegen=max_colors=96:stats_mode=diff[p];[b][p]paletteuse=dither=none:diff_mode=rectangle"
    system("ffmpeg", "-loglevel", "error", "-y", "-framerate", "12", "-i", pattern,
      "-vf", filters, "-loop", "0", path, exception: true)
  end
end
