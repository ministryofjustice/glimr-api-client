[![CircleCI](https://circleci.com/gh/ministryofjustice/glimr-api-client.svg?style=svg&circle-token=1d291c45a14d48ef123ffd904169e10b7f47411f)](https://circleci.com/gh/ministryofjustice/glimr-api-client)

# GlimrApiClient

A simple client to integrate with the GLiMR case management system in
use in various UK tribunals.

## Usage

### Check Availablity

```ruby
GlimrApiClient::Available.call.available?
```

Check if the GLiMR API is available.  Raises
`GlimrApiClient::Unavailable` if anything other than a positive response
is received; this includes network errors and timeouts.

### Find a case

```ruby
GlimrApiClient::Case.find(<case reference>)
```

Find a case on GLiMR using the case reference (‘TT/2012/00001’ in Tax
Tribunals, for example). `#title` returns case title from GLiMR, and `#fees`
returns an array of anonymous objects (OpenStructs) detailing any
outstanding fees. Each fee object responds to `#glimr_id`,
`#description`, and `#amount`.

Please note that `#amount` returns the amount in pence.

If a case is not found, the client will raise `GlimrApiClient::CaseNotFound`.

### Update a case, mark as paid

```ruby
GlimrApiClient::Update.call(<Fee object>)
```

Update a GLiMR case to indicate that payment has been received for a
fee. The fee object passed must respond to `#glimr_id`,
`#govpay_reference`, `#govpay_payment_id`, and `#amount`.  `#amount`
must be the amount in pence. The client will validate the request and raise
`GlimrApiClient::RequestError` if any of these methods are missing.

Network errors or API failures will raise
`GlimrApiClient::PaymentNotificationFailure`.

### Examples

See the dummy Rails app in `/spec/dummy` for examples of how the gem might
be used in a production environment.

## Installation

Add this line to your application’s Gemfile:

```ruby
gem 'glimr-api-client'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install glimr-api-client
```

## Testing

Run `bundle rake` in the gem source directory for a full set of specs,
mutation tests and rubocop checks.

### Shared examples

The gem can install a set of shared examples in your app that will stub
a sensible set of API calls using Excon’s stubbing functionality. To
install these, install the gem, make sure you have the `spec/support`
subdirectory then run:

```ruby
bundle exec rake rake glimr_api_client:install_shared_examples
```

This will install `spec/support/shared_examples_for_glimr.rb`.

Lastly, add these lines to `spec/rails_helper`:

```ruby
  config.before(:all) do
    Excon.defaults[:mock] = true
  end

  config.after(:each) do
    Excon.stubs.clear
  end
```

## Contributing

Fork, then clone the repo:

```bash
git clone git@github.com:your-username/glimr-api-client.git
```

Make sure the tests pass:

```bash
bundle
bundle exec rake
```

Make your change. Add specs for your change. Make the specs pass:

```bash
bundle exec rake
```

Push to your fork and [submit a pull request][pr].

[pr]: https://github.com/ministryofjustice/glimr-api-client/compare

Some things that will increase the chance that your pull request is
accepted:

* Write specs.
* Make sure you don’t have any mutants (part of total test suite).
* Write a [good commit message][commit].

[commit]: https://github.com/alphagov/styleguides/blob/master/git.md

## License
Released under the [MIT License](http://opensource.org/licenses/MIT).
Copyright (c) 2015-2016 Ministry of Justice.

