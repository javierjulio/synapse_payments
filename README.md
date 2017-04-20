# DEPRECATED

This is no longer supported or used since SynapsePay has incorporated these changes (mostly the detailed integration tests) into their [own official Ruby SDK](https://github.com/synapsepay/SynapsePayRest-Ruby) which has improved substantially. I'm not interested in doing more development for new or updated features so I've transitioned to using their SDK while also [making various contributions](https://github.com/synapsepay/SynapsePayRest-Ruby/pulls?q=is%3Apr+is%3Aclosed+author%3Ajavierjulio).

# The SynapsePayments Ruby Gem

A tested Ruby interface to the [SynapsePay v3 API](http://docs.synapsepay.com/v3.1). Note: Requires **Ruby 2.1 and up**. Not all API actions are supported. Find out more in the TODO section.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'synapse_payments'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install synapse_payments

To try out the gem and experiment, you're better off following the development instructions.

## Usage

Check out [samples.md](samples.md) to review how to use this library.

## Development

1. Clone the repo: `git clone https://github.com/javierjulio/synapse_payments.git`
2. Use Ruby 2.1 and up. If you need to install use [rbenv](https://github.com/sstephenson/rbenv) and [ruby-build](https://github.com/sstephenson/ruby-build) and then run:

        gem update --system
        gem update
        gem install bundler --no-rdoc --no-ri

3. From project root run `./bin/setup` script
4. Run `./bin/console` to experiment with an authenticated `client` and `fingerprint`:

  ```ruby
  fingerprint
  # => acb123...
  
  users = client.users.all
  puts users
  # => {...
  ```

### TODO

* add pagination/querying to method `all` for users, nodes, transactions, and subscriptions
* consider creating a `Response` object wrapper
* clean up object/folder structure
* reorganize integration tests
* integration test ```test_sending_money``` does not create a SYNAPSE_US account before trying to access it
* probably need to create document classes to refactor new KYC methods in UserClient
* enable creating other account types besides ACH-US
* HMAC signature validation
* autogenerate fingerprint from client_id/client_secret

### Tests

Run `bundle exec rake test`. To include integration tests run with `USER_ID=YOUR_USER_ID` being a user you created in sandbox.

### Releasing

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/javierjulio/synapse_payments. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
