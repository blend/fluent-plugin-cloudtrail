require 'json'
require 'stringio'
require 'zlib'
require 'aws-sdk'

module Fluent

  class CloudtrailInput < Input
    USER_AGENT_NAME = 'fluent-plugin-cloudtrail-in'
    PLUGIN_VERSION = '0.0.1'

    Plugin.register_input('cloudtrail', self)

    define_method('log')    { $log }   unless method_defined?(:log)
    define_method('router') { Engine } unless method_defined?(:router)

    config_param :aws_key_id,  :string, :default => nil, :secret => true
    config_param :aws_sec_key, :string, :default => nil, :secret => true
    # The 'region' parameter is optional because
    # it may be set as an environment variable.
    config_param :region, :string, :default => nil

    config_param :profile,          :string, :default => nil
    config_param :credentials_path, :string, :default => nil
    config_param :role_arn,         :string, :default => nil
    config_param :external_id,      :string, :default => nil

    config_param :sqs_url, :string
    config_param :receive_interval, :time, :default => 0.1
    config_param :max_number_of_messages, :integer, :default => 10
    config_param :wait_time_seconds, :integer, :default => 10

    config_param :http_proxy, :string, :default => nil
    config_param :debug, :bool, :default => false

    config_param :tag, :string

    def configure(conf)
      super
    end

    def initialize
      super
    end

    def start
      super
      load_clients
      @finished = false
      @thread = Thread.new(&method(:run_periodic))
    end

    def shutdown
      super
      @finished = true
      @thread.join
    end

    def load_clients
      user_agent_suffix = "#{USER_AGENT_NAME}/#{PLUGIN_VERSION}"
      options = {
        user_agent_suffix: user_agent_suffix
      }
      if @region
        options[:region] = @region
      end

      if @aws_key_id && @aws_sec_key
        options.update(
          access_key_id: @aws_key_id,
          secret_access_key: @aws_sec_key,
        )
      elsif @profile
        credentials_opts = {:profile_name => @profile}
        credentials_opts[:path] = @credentials_path if @credentials_path
        credentials = Aws::SharedCredentials.new(credentials_opts)
        options[:credentials] = credentials
      elsif @role_arn
        credentials = Aws::AssumeRoleCredentials.new(
          client: Aws::STS::Client.new(options),
          role_arn: @role_arn,
          role_session_name: "fluent-plugin-cloudtrail",
          external_id: @external_id,
          duration_seconds: 60 * 60,
        )
        options[:credentials] = credentials
      end

      if @debug
        options.update(
          logger: Logger.new(log.out),
          log_level: :debug
        )
        # XXX: Add the following options, if necessary
        # :http_wire_trace => true
      end

      if @http_proxy
        options[:http_proxy] = @http_proxy
      end

      @s3_client = Aws::S3::Client.new(options)
      @sqs_client = Aws::SQS::Client.new(options)
    end

    def run_periodic
      until @finished
        begin
          sleep @receive_interval
          sqs_resp = @sqs_client.receive_message(
            queue_url: @sqs_url,
            max_number_of_messages: @max_number_of_messages,
            wait_time_seconds: @wait_time_seconds
          )
          for message in sqs_resp.messages
            body_obj = JSON.parse(message.body)
            message_obj = JSON.parse(body_obj['Message'])
            s3_bucket = message_obj['s3Bucket']
            for s3_object_key in message_obj['s3ObjectKey']
              s3_resp = @s3_client.get_object(
                :bucket => s3_bucket,
                :key => s3_object_key
              )
              io = StringIO.new
              io.write s3_resp.body.read
              io.rewind
              gz = Zlib::GzipReader.new(io)
              cloudtrail_data = gz.read
              gz.close
              cloudtrail_records = JSON.parse(cloudtrail_data)['Records']
              for record in cloudtrail_records
                router.emit(@tag, Time.now.to_i, record)
              end
            end

            @sqs_client.delete_message(
              queue_url: @sqs_url,
              receipt_handle: message.receipt_handle
            )
          end
        rescue
          log.error "failed to emit", :error => $!.to_s, :error_class => $!.class.to_s
          log.warn_backtrace $!.backtrace
        end
      end
    end
  end
end
