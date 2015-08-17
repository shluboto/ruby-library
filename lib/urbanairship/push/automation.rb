require 'urbanairship'
require 'time'


module Urbanairship
  module Push
    class AutomatedMessage
      include Urbanairship::Common
      include Urbanairship::Loggable

      def initialize(client: required('client'))
        @client = client
      end

      def create(pipelines: required('pipelines'))
        resp = @client.send_request(
          method: 'POST',
          url: PIPELINES_URL,
          body: JSON.dump(pipelines),
          content_type: 'application/json'
        )
        logger.info('Created an automated message: #{pipelines}')
        resp
      end

      def validate(pipelines: required('pipeline'))
        resp = @client.send_request(
          method: 'POST',
          url: PIPELINES_URL + 'validate',
          body: JSON.dump(pipelines),
          content_type: 'application/json'
        )
      end

      def list_existing(start: nil, enabled: nil)
        fail ArgumentError, 'start needs to be a string' unless start == nil or start.is_a? String
        fail ArgumentError,
          'enabled needs to be a boolean' unless start == nil or (enabled == true or enabled == false)
        url = PIPELINES_URL
        if start != nil
          url += '?start=' + start
          url += '&enabled=' + enabled unless enabled.nil?
        else
          url += '?enabled=' + enabled unless enabled.nil?
        end

        resp = @client.send_request(
          method: 'GET',
          url: url
        )
        logger.info('Retrieved a list of existing pipelines.')
        resp
      end

      def list_deleted(start: nil)
        date_parsed = nil
        begin
          date_parsed = Time.parse(start) unless start.nil?
        rescue ArgumentError
          fail ArgumentError,
               'date must be a valid date string'
        end
        url = PIPELINES_URL + 'deleted/'
        url += '?start=' + date_parsed.iso8601 unless date_parsed.nil?
        resp = @client.send_request(
          method: 'GET',
          url: url
        )
        logger.info('Retrieved list of deleted pipelines')
        resp
      end

      def lookup(pipeline_id: required('pipeline_id'))
        fail ArgumentError, 'pipeline_id needs to be a string' unless pipeline_id.is_a? String
        resp = @client.send_request(
          method: 'GET',
          url: PIPELINES_URL + pipeline_id
        )
        logger.info('Retrieved info for pipeline #{pipeline_id}')
        resp
      end

      def update(pipeline_id: required('pipeline_id'), pipeline: required('pipeline'))
        fail ArgumentError 'pipeline_id should be a string' unless pipeline_id.is_a? String
        resp = @client.send_request(
          method: 'PUT',
          url: PIPELINES_URL + pipeline_id,
          body: JSON.dump(pipeline),
          content_type: 'application/json'
        )
        logger.info('Updated state of pipeline #{pipeline_id} to #{pipeline}')
        resp
      end
    end
  end
end