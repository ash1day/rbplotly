# PlotlyRuby

[Plot.ly](https://plot.ly/) API client and Interface to [plotly.js](https://plot.ly/javascript/).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'plotly_ruby'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install plotly_ruby

## Usage

### Plotly Offline

```ruby
require 'plotly'

n = 100

x  = (0..n).map { |i| i.to_f / n }
y0 = (0..n).map { rand(-2.0..2.0) + 5 }
y1 = (0..n).map { rand(-2.0..2.0) }
y2 = (0..n).map { rand(-2.0..2.0) - 5 }

trace0 = {
  x: x,
  y: y0,
  type: 'scatter',
  mode: 'markers'
}

trace1 = trace0.merge(y: y1, mode: 'markers+lines')
trace2 = trace0.merge(y: y2, mode: 'lines')

Plotly::Offline.plot([trace0, trace1, trace2], path: 'line_and_scatter.html')
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/y4ashida/plotly_ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

Copyright (c) 2016 Yoshihiro Ashida. See [LICENSE.txt](LICENSE.txt) for
further details.
