# hash_param

hash_param is an library that converts functions that take a single "data"
argument Hash into a function that takes named, formal parameters.  This allows
APIs like ActionCable to be a little easier to work with.

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
  hash_param :send_message, :typing_status

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

After named positional arguments, `hash_param` will try to fill named keyword
arguments, then will send the rest to `**kwrest` if listed, and lastly, will
send whats left of the data object to `*args`.  In practice, this means you'll
never get values in both `*args` and `**kwrest`.

`*args` parameters keep the string key names, while `**kwrest` hashes get their
keys converted into symbols.  If there are no values to pass to `*args`, you'll
get an empty list, not a list containing an empty Hash.

If the argument list cannot be satisfied, `ArgumentError` is raised.  Extraneous
properties sent to the method are ignored if not consumed through the argument
list.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hash_param'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hash_param

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/metermd/hash_param.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
