require "spec_helper"

RSpec.describe DelayedJobLogging do
  describe ".logger & .logger=" do
    let(:logger) { double("Logger") }
    let(:delayed_job_logger) { double("DelayedJobLogger") }

    before do
      DelayedJobLogging.logger = logger
      allow(Delayed::Job).to receive(:logger) { delayed_job_logger }
    end

    after do
      DelayedJobLogging.logger = nil
    end

    context "when a logger was assigned" do
      it "returns the assigned logger" do
        expect(DelayedJobLogging.logger).to eq(logger)
      end
    end

    context "when no logger was assigned" do
      let(:logger) { nil }

      it "falls back to the logger from Delayed::Job" do
        expect(DelayedJobLogging.logger).to eq(delayed_job_logger)
      end
    end

    context "when both DelayedJobLogging and Delayed::Job don't have a logger" do
      let(:logger) { nil }
      let(:delayed_job_logger) { nil }

      it "raises an exception" do
        expect { DelayedJobLogging.logger }.to raise_exception(RuntimeError)
      end
    end
  end

  context "callbacks" do
    class SuccessWorker
      include DelayedJobLogging

      def initialize
        @var1 = "hello World"
        @var2 = 2223
      end

      def perform
        "success!"
      end
    end

    class FailureException < RuntimeError; end
    class FailureWorker
      include DelayedJobLogging

      def perform
        fail(FailureException, "I'm a miserable failure", %w(fake backtrace))
      end
    end

    let(:logger) do
      Class.new do
        def info(msg)
          messages << msg
        end

        def decoded_messages(filter_status: :all)
          messages.map(&method(:decode)).select do |hash|
            filter_status == :all || hash[:status] == filter_status
          end
        end

        private def messages
          @_messages ||= []
        end

        private def decode(msg)
          JSON.parse(msg)
        rescue JSON::ParseError
          msg
        end
      end.new
    end

    before do
      Delayed::Worker.delay_jobs = false
      Delayed::Worker.default_queue_name = "default"
      allow_any_instance_of(Delayed::Job).to receive(:id) { 123 }
      DelayedJobLogging.logger = logger
    end

    def enqueue_and_execute(worker)
      # The FailureWorker will raise an exception which we need to rescue from.
      # But we're interested in the logging done my Delayed::Job and not in the
      # exception itself.
      # rubocop:disable Lint/HandleExceptions
      Delayed::Job.enqueue(worker)
    rescue FailureException
    end # rubocop:enable Lint/HandleExceptions

    def hash_with(status:)
      {
        "job_attempts" => 0,
        "job_exception" => nil,
        "job_id" => 123,
        "job_priority" => 0,
        "job_queue" => "default",
        "job_run_at" => Time.now.iso8601,
        "job_status" => status
      }
    end

    def success_hash_with(status:)
      hash_with(status: status).merge(
        "job_worker_name" => "SuccessWorker",
        "job_arguments" => { "@var1" => "hello World", "@var2" => 2223 }
      )
    end

    def failure_hash_with(status:, exception: nil)
      hash_with(status: status).merge(
        "job_exception" => exception,
        "job_worker_name" => "FailureWorker",
        "job_arguments" => {}
      )
    end

    describe "#enqueue" do
      it "logs the SuccessWorker" do
        Timecop.freeze do
          enqueue_and_execute(SuccessWorker.new)

          expect(logger.decoded_messages).to include(
            success_hash_with(status: "enqueued")
          )
        end
      end

      it "logs the FailureWorker" do
        Timecop.freeze do
          enqueue_and_execute(FailureWorker.new)

          expect(logger.decoded_messages).to include(
            failure_hash_with(status: "enqueued")
          )
        end
      end
    end

    describe "#before" do
      it "logs the SuccessWorker" do
        Timecop.freeze do
          enqueue_and_execute(SuccessWorker.new)

          expect(logger.decoded_messages).to include(
            success_hash_with(status: "started")
          )
        end
      end

      it "logs the FailureWorker" do
        Timecop.freeze do
          enqueue_and_execute(FailureWorker.new)

          expect(logger.decoded_messages).to include(
            failure_hash_with(status: "started")
          )
        end
      end
    end

    describe "#success" do
      it "logs the SuccessWorker" do
        Timecop.freeze do
          enqueue_and_execute(SuccessWorker.new)

          expect(logger.decoded_messages).to include(
            success_hash_with(status: "succeeded")
          )
        end
      end

      it "doesn't log the FailureWorker" do
        enqueue_and_execute(FailureWorker.new)

        expect(logger.decoded_messages(filter_status: "succeeded")).to be_empty
      end
    end

    describe "#error" do
      it "logs the FailureWorker" do
        Timecop.freeze do
          enqueue_and_execute(FailureWorker.new)

          expect(logger.decoded_messages).to include(
            failure_hash_with(status: "failed", exception:  "FailureException: I'm a miserable failure\nfake\nbacktrace")
          )
        end
      end

      it "doesn't log the SuccessWorker" do
        enqueue_and_execute(SuccessWorker.new)

        expect(logger.decoded_messages(filter_status: "failed")).to be_empty
      end
    end
  end
end
