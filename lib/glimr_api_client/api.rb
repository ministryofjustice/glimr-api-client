module GlimrApiClient
  module Api
    class PaymentNotificationFailure < StandardError; end
    class Unavailable < StandardError; end
    class CaseNotFound < StandardError; end

    def post
      @post ||=
        client.post(path: endpoint, body: request_body.to_query).tap { |resp|
          # Only timeouts and network issues raise errors.
          handle_response_errors(resp)
          @body = resp.body
          @status = resp.status
        }
    rescue Excon::Error => e
      if endpoint == '/paymenttaken'
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
      if resp.status == 404
        raise CaseNotFound
      elsif (400..599).cover?(resp.status) && endpoint == '/paymenttaken'
        raise PaymentNotificationFailure, resp.status
      elsif (400..599).cover?(resp.status)
        raise Unavailable, resp.status
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
