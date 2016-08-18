# Rbplotly

[Plot.ly](https://plot.ly/) API client and Interface to [plotly.js](https://plot.ly/javascript/).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rbplotly'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rbplotly

## Usage

### Plotly Offline

```ruby
require 'rbplotly'

n = 100

x  = (1...n).map { |i| i.to_f / n }
y0 = (1...n).map { rand(-2.0...2.0) + 5 }
y1 = (1...n).map { rand(-2.0...2.0) }
y2 = (1...n).map { rand(-2.0...2.0) - 5 }

trace0 = { x: x, y: y0, type: 'scatter', mode: 'markers' }
trace1 = trace0.merge(y: y1, mode: 'markers+lines')
trace2 = trace0.merge(y: y2, mode: 'lines')

data = [trace0, trace1, trace2]

plot = Plotly::Plot.new(data: data)

plot.generate_html(path: 'tmp/scatter_and_line.html')
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/y4ashida/rbplotly. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

Copyright (c) 2016 Yoshihiro Ashida. See [LICENSE.txt](LICENSE.txt) for
further details.
