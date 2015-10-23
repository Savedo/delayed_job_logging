# Delayed::Job Logging

This provides a module to log enqueuing and performing Delayed::Jobs task in a JSON format.

Example output when sent to `syslog`:

```json
Oct 20 14:05:27 savedo-web savedo-web-development[10694]: {"job_attempts":0,"job_exception":null,"job_id":null,"job_worker_name":"CustomerMailerWorker","job_arguments":{"@email":"confirmation_instructions","@vars":[8,"RxJWZzJKdr3VP8zzr7sd",{}]},"job_priority":0,"job_queue":"default","job_run_at":"2015-10-20T14:05:27+00:00","job_status":"enqueued"}
Oct 20 14:05:27 savedo-web savedo-web-development[10695]: {"job_attempts":0,"job_exception":null,"job_id":94,"job_worker_name":"CustomerMailerWorker","job_arguments":{"@email":"confirmation_instructions","@vars":[8,"RxJWZzJKdr3VP8zzr7sd",{}]},"job_priority":0,"job_queue":"default","job_run_at":"2015-10-20T14:05:27Z","job_status":"started"}
Oct 20 14:05:29 savedo-web savedo-web-development[10695]: {"job_attempts":0,"job_exception":null,"job_id":94,"job_worker_name":"CustomerMailerWorker","job_arguments":{"@email":"confirmation_instructions","@vars":[8,"RxJWZzJKdr3VP8zzr7sd",{}]},"job_priority":0,"job_queue":"default","job_run_at":"2015-10-20T14:05:27Z","job_status":"succeeded"}
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'delayed_job_logging'
```

And then execute:

```sh
bundle
```

## Usage

Just include the `DelayedJobLogging` module in your task definition. If you define `enqueue`, `before`, `success` or `error` in your task, you have to call `super`:

```ruby
class NewsletterJob
  include DelayedJobLogging

  def initialize(email)
    @email = email
  end

  def perform
    do_stuff(@email)
  end

  def error(job, exception)
    super # calls the logging
    Airbrake.report(...)
  end
end
```

Per default, DelayedJobLogging loggs to the logger registered to the `Delayed::Job` model (which itself defaults to `Rails.logger`), but you can set your own logger object:

```ruby
require "logger"

DelayedJobLogging.logger = Logger.new(STDOUT)
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Savedo/delayed_job_logging. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

