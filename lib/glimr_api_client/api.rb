module GlimrApiClient
  module Api

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
        raise GlimrApiClient::PaymentNotificationFailure, e
      else
        raise GlimrApiClient::Unavailable, e
      end
    end

    def response_body
      @response_body ||= JSON.parse(@body, symbolize_names: true)
    end

    private

    def handle_response_errors(resp)
      if resp.status == 404
        raise GlimrApiClient::CaseNotFound
      elsif (400..599).cover?(resp.status) && endpoint == '/paymenttaken'
        raise GlimrApiClient::PaymentNotificationFailure, resp.status
      elsif (400..599).cover?(resp.status)
        raise GlimrApiClient::Unavailable, resp.status
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
