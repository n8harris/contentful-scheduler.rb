# Contentful Scheduler

Scheduling Server for Contentful entries.

## Contentful
[Contentful](http://www.contentful.com) is a content management platform for web applications,
mobile apps and connected devices. It allows you to create, edit & manage content in the cloud
and publish it anywhere via powerful API. Contentful offers tools for managing editorial
teams and enabling cooperation between organizations.

## What does `contentful-scheduler` do?
The aim of `contentful-scheduler` is to have developers setting up their Contentful
entries for scheduled publishing.

## Requirements

* [Redis](http://redis.io/)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'contentful-scheduler'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install contentful-scheduler

## Usage

The best way to use Scheduler is as a stand-alone application that wraps Scheduler and Resque on an execution pipe using [Foreman](http://ddollar.github.io/foreman/).

To do this, you need to follow the next steps:

* Create a new folder
* Create a `Gemfile` with the following:

```ruby
source 'https://rubygems.org'

gem 'contentful-scheduler', '~> 0.1'
gem 'contentful-webhook-listener', '~> 0.2'
gem 'contentful-management', '~> 1.0'
gem 'resque', '~> 1.0'
gem 'resque-scheduler', '~> 4.0'
gem 'rake'
```

* Create a `Procfile` with the following:

```
entry_scheduler: env bundle exec rake contentful:scheduler
resque: env bundle exec rake resque:work
resque_scheduler: env bundle exec rake resque:scheduler
```

* Create a `Rakefile` with the following:

```ruby
require 'contentful/scheduler'

$stdout.sync = true

config = {
  redis: {
    host: 'localhost',
    port: 6379
  },
  spaces: {
    'YOUR_SPACE_ID' => {
      publish_field: 'publishDate'
    }
  },
  management_token: 'YOUR_TOKEN'
}

namespace :contentful do
  task :setup do
    Contentful::Scheduler.config = config
  end

  task :scheduler => :setup do
    Contentful::Scheduler.start
  end
end

require 'resque/tasks'
require 'resque/scheduler/tasks'

namespace :resque do
  task :setup => 'contentful:setup' do
    ENV['QUEUE'] = '*'
  end

  task :setup_schedule => :setup do
    require 'resque-scheduler'
  end

  task :scheduler => :setup_schedule
end
```

* Run the Application:

```bash
$ foreman start
```

You can get the templates for all these files in the [`example/`](./example) directory

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/contentful/contentful-scheduler.rb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
