[![Gem Version](https://badge.fury.io/rb/rbplotly.svg)](https://badge.fury.io/rb/rbplotly)
[![Dependency Status](https://gemnasium.com/badges/github.com/y4ashida/rbplotly.svg)](https://gemnasium.com/github.com/y4ashida/rbplotly)
[![Build Status](https://travis-ci.org/y4ashida/rbplotly.svg?branch=master)](https://travis-ci.org/y4ashida/rbplotly)
[![Code Climate](https://codeclimate.com/github/y4ashida/rbplotly/badges/gpa.svg)](https://codeclimate.com/github/y4ashida/rbplotly)

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

```ruby
require 'rbplotly'

x = [0, 1, 2, 3, 4]
trace0 = { x: x, y: [0, 2, 1, 4, 3], type: :scatter, mode: :lines }
trace1 = { x: x, y: [4, 1, 3, 0, 2], type: :scatter, mode: 'markers+lines' }
data = [trace0, trace1] # data must be Array

layout = { width: 500, height: 500 }

plot = Plotly::Plot.new(data: data, layout: layout)

plot.layout.height = 300 # You can change plot's attributes.

plot.generate_html(path: './line_chart.html')
```

![](./docs/images/line_chart.png)

Use `#download_image` if you want to get an image by using Plot.ly API. You can get your API KEY [here](https://plot.ly/settings/api).

```ruby
Plotly.auth(<YOUR_USERNAME>, <YOUR_API_KEY>)
plot.download_image(path: './line_chart.png')
```

Or use `#show` on IRuby notebooks.

```ruby
plot.show
```

## Examples

Visit [nbviewer.jupyter.org/github/y4ashida/rbplotly](https://nbviewer.jupyter.org/github/y4ashida/rbplotly/tree/master/examples/) to see more examples.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/y4ashida/rbplotly. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Thanks

`rbplotly` is based on [plotly/plotly.py](https://github.com/plotly/plotly.py), so there are a lot of code coming from it.

## License

Copyright (c) 2016 Yoshihiro Ashida. See [LICENSE.txt](LICENSE.txt) for
further details.
