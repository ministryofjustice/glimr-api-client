[![CircleCI](https://circleci.com/gh/ministryofjustice/glimr-api-client.svg?style=svg&circle-token=1d291c45a14d48ef123ffd904169e10b7f47411f)](https://circleci.com/gh/ministryofjustice/glimr-api-client)

# GlimrApiClient

A simple client to integrate with the GLiMR case management system in
use in various UK tribunals.

## Usage

### Configuration

The gem expects a `GLIMR_API_URL` environment variable, providing the
endpoint at which the API can be found. This will be something like;
`https://glimr-api.taxtribunals.dsd.io`

This URL must be accessible from wherever your code is running.

If you need to set the api timeout, use the `GLIMR_API_TIMEOUT_SECONDS`
environment variable.  This defaults to 5 seconds.

The call to register new cases can take a long time.  It has its own
timeout as a result: 32 seconds. Use the
`GLIMR_REGISTER_NEW_CASE_TIMEOUT_SECONDS` environment variable to
override this.

### Check Availablity

```ruby
GlimrApiClient::Available.call.available?
```

Check if the GLiMR API is available.  Raises
`GlimrApiClient::Unavailable` if anything other than a positive response
is received; this includes network errors and timeouts.

### Register a New Case

```ruby
GlimrApiClient::RegisterNewCase.call(<case parameters>)
```

Accepts the following parameters:

```ruby
  jurisdictionId: 8,
  onlineMappingCode: 'something',
  contactPhone: '1234',
  contactFax: '5678',
  contactEmail: 'foo_at_bar.com',
  contactPreference: 'Email',
  contactFirstName: 'Alice',
  contactLastName: 'Caroll',
  contactStreet1: '5_Wonderstreet',
  contactStreet2: 'contact_street_2',
  contactStreet3: 'contact_street_3',
  contactStreet4: 'contact_street_4',
  contactCity: 'London',
  documentsURL: 'http...google.com',
  repPhone: '7890',
  repFax: '6789',
  repEmail: 'bar_at_baz.com',
  repPreference: 'Fax',
  repReference: 'MYREF',
  repIsAuthorised: 'Yes',
  repOrganisationName: 'Acme._Ltd.',
  repFAO: 'Bob_Hope',
  repStreet1: '5_Repstreet',
  repStreet2: 'Repton',
  repStreet3: 'Repshire',
  repStreet4: 'Rep_st._4',
  repCity: 'City_of_reps'
```

Currently only `jurisdictionId` and `onlineMappingCode` are mandatory.

## Deprecated Calls

Pending a Ministerial review of fees in tribunals, the four method
related to managing payment were deprecated in late April, 2017.

In the event that these methods are required at a later date, the code
can be re-vivfied in the repo. See the following commit for details of
files removed:

02fe1117956089a4b2e62f2e93540165443de06e

The specs may require some adaption.

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

### In an application

Examples of how this gem might be used can be found in the specs.  There
is also a set of RSpec shared examples that can be copied and modified.
These can be found in `spec/suppport/shared_examples_for_govpay.rb`.

## Contributing

Fork, then clone the repo:

```bash
git clone git@github.com:your-username/glimr-api-client.git
```

Make sure the tests pass:

```bash
bundle
bundle db:setup
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

