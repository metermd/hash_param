# actioncable_auto_param

actioncable_auto_param is an ActionCable add-on that automatically extracts
parameters from the data object passed to ActionCable Channel action methods.

For example, it can turn this:

```ruby
class ChatChannel < ApplicationCable::Channel
  def send_message(data)
    chat_id = data['chat_id']
    author_id = data['author_id']
    body = data['body']
    # ...
  end

  def typing_status(data)
    chat_id = data['chat_id']
    user_id = data['user_id']
    status = data['status'] || 'typing'
    # ...
  end
end
```

into this:

```ruby
class ChatChannel < ApplicationCable::Channel
  auto_param :all # or: `auto_param :send_message, :typing_status`

  def send_message(chat_id, author_id, body)
    # ...
  end

  def typing_status(chat_id, user_id, status = 'typing')
    # ...
  end
end
```

It does this by looking at your method signature and filling in parameters by
name from the data object.  It plays nice with default parameters, keyword
arguments, both optional and required, `*rest` and `**kwrest` parameters.

After named positional arguments, `auto_param` will try to fill named keyword
arguments, then will send the rest to `**kwrest` if listed, and lastly, will
send whats left of the data object to `*args`.  In practice, this means you'll
never get values in both `*args` and `**kwrest`.

`*args` parameters keep the string key names, while `**kwrest` hashes get their
keys converted into symbols.  If there are no values to pass to `*args`, you'll
get an empty list, not a list containing an empty Hash.

If the argument list cannot be satisfied, `ArgumentError` is raised.  Extraneous
properties sent to the action are ignored if not consumed through the argument
list.

ActionCable is still on shaky API ground, and so is this gem.  It's effectively
a monkey patch, so that makes it even more brittle.  Be advised.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'actioncable_auto_param'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install actioncable_auto_param

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/metermd/actioncable_auto_param.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
