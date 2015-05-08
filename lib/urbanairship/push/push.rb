require 'json'

require 'ext/object'
require 'urbanairship/common'
require 'urbanairship/loggable'


# In the Python library, this file is named `core.py`. Here it's
# `push.rb` in keeping with the Ruby convention of naming the
# file based on the class it contains.
module Urbanairship
  module Push

    # A push notification.
    class Push
      attr_writer :client, :audience, :notification, :options,
                  :device_types, :message
      attr_reader :device_types
      include Urbanairship::Common
      include Urbanairship::Loggable

      def initialize(client)
        @client = client
      end

      def payload
        {
          audience: @audience,
          notification: @notification,
          options: @options,
          device_types: @device_types,
          message: @message
        }.compact
      end

      # Send the notification.
      #
      # Named #send_push instead of #send like the Python library,
      # because #send is a method of Ruby's #Object.
      #
      # @raise [AirshipFailure (TBD)] if the request failed
      # @raise [Unauthorized (TBD)] if authentication failed
      # @return [PushResponse] with `push_ids` and other response data.
      def send_push
        response_body = @client.send_request(
          method: 'POST',
          body: JSON.dump(payload),
          url: PUSH_URL,
          content_type: 'application/json',
          version: 3
        )
        pr = PushResponse.new(http_response_body: response_body)
        logger.info { "Push successful. Push ID's: #{pr.push_ids.join(', ')}" }
        pr
      end
    end


    class ScheduledPush
      attr_writer :schedule, :name, :push, :url
      attr_reader :url, :push
      include Urbanairship::Common
      include Urbanairship::Loggable

      def initialize(client)
        @client = client
      end

      def payload
        {
          name: @name,
          schedule: @schedule,
          push: @push.payload
        }.compact
      end

      # Schedule the notification
      #
      # @raise [AirshipFailure (TBD)] if the request failed
      # @raise [Unauthorized (TBD)] if authentication failed
      # @return [PushResponse] with `schedule_url` and other response data.
      def send_push
        response_body = @client.send_request(
          method: 'POST',
          body: JSON.dump(payload),
          url: SCHEDULES_URL,
          content_type: 'application/json',
          version: 3
        )
        pr = PushResponse.new(http_response_body: response_body)
        logger.info { "Scheduled push successful: #{pr.inspect}" }
        @url = pr.schedule_url
      end

      def self.from_url(client:, url:)
        scheduled_push = ScheduledPush.new(client)
        response_body = client.send_request(
          method: 'GET',
          body: nil,
          url: url,
          version: 3
        )
        payload = JSON.load(response_body)
        scheduled_push.name = payload['name']
        scheduled_push.schedule = payload['schedule']
        scheduled_push.push = Push.new(client)
        scheduled_push.push.audience = payload['push']['audience']
        scheduled_push.push.notification = payload['push']['notification']
        scheduled_push.push.device_types = payload['push']['device_types']
        scheduled_push.push.message = payload['push']['message']
        scheduled_push.push.options = payload['push']['options']
        scheduled_push.url = url
        scheduled_push
      end
    end


    # Response to a successful push notification send or schedule.
    #
    # Right now this is a fairly simple wrapper around the json payload
    # response, but making it an object gives us some flexibility to add
    # functionality later.
    #
    class PushResponse
      attr_reader :ok, :push_ids, :schedule_url, :operation_id, :payload

      def initialize(http_response_body:)
        @payload = JSON.load(http_response_body)
        @ok = @payload['ok']
        @push_ids = @payload['push_ids']
        @schedule_url = @payload['schedule_urls'].try(:first)
        @operation_id = @payload['operation_id']
      end
    end

  end
end
