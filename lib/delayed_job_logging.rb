require "delayed_job_logging/version"

# Delayed Job Workers including this will log when a job was enqueued, started,
# succeeded or failed to the Rails logs.
# It's important to call `super` if they implement these callback methods:
# `enqueue`, `before`, `success` or `error`
module DelayedJobLogging
  class << self
    attr_writer :logger

    def logger
      @logger || Delayed::Job.logger || fail("No logger available!")
    end
  end

  def enqueue(job)
    LogMessage.new(job).log("enqueued")
  end

  def before(job)
    LogMessage.new(job).log("started")
  end

  def success(job)
    LogMessage.new(job).log("succeeded")
  end

  def error(job, exception)
    LogMessage.new(job).log("failed", exception: exception)
  end

  class LogMessage
    attr_reader :job
    private :job

    def initialize(job)
      @job = job
    end

    def log(status, exception: nil)
      DelayedJobLogging.logger.info(
        ActiveSupport::JSON.encode(
          message_for(status, exception: exception)
        )
      )
    end

    # The method constructs a hash. Imnsho all alternatives would be inferior to this.
    # rubocop:disable Metrics/MethodLength
    private def message_for(status, exception:)
      {
        job_attempts: job.attempts,
        job_exception: format_exception(exception),
        job_id: job.id,
        job_worker_name: worker.class.name,
        job_arguments: job_arguments,
        job_priority: job.priority,
        job_queue: job.queue,
        job_run_at: (job.run_at || Time.now).iso8601,
        job_status: status
      }
    end # rubocop:enable Metrics/MethodLength

    private def job_arguments
      worker.instance_variables.inject({}) do |vars, var|
        vars.merge(var => worker.instance_variable_get(var))
      end
    end

    private def worker
      @_worker ||= YAML.load(job.handler)
    end

    private def format_exception(exception)
      return unless exception

      "#{exception.class}: #{exception.message}\n" +
        exception.backtrace.join("\n")
    end
  end
end
