require 'excon'
require 'active_support'
require 'active_support/core_ext/object/to_query'

module GlimrApiClient
  module Api
    def post
      @post ||=
        client.post(path: endpoint, body: request_body.to_query).tap { |resp|
          # Only timeouts and network issues raise errors.
          handle_response_errors(resp)
          @body = resp.body
        }
    rescue Excon::Error => e
      if endpoint.eql?('/paymenttaken')
        raise PaymentNotificationFailure, e
      else
        raise Unavailable, e
      end
    end

    def response_body
      @response_body ||= JSON.parse(@body, symbolize_names: true)
    end

    private

    def handle_response_errors(resp)
      if (!endpoint.eql?('/paymenttaken') && resp.status.equal?(404))
        raise CaseNotFound, resp.status
      elsif (400..599).cover?(resp.status)
        if endpoint.eql?('/paymenttaken')
          raise PaymentNotificationFailure, resp.status
        else
          raise Unavailable, resp.status
        end
      end
    end

    def client
      @client ||= Excon.new(
        ENV.fetch('GLIMR_API_URL', 'https://glimr-test.dsd.io'),
        headers: {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        },
        persistent: true
      )
    end
  end
end
