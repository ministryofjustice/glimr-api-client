require 'excon'

module GlimrApiClient
  module Api
    def post
      client("#{api_url}#{endpoint}").post(body: request_body.to_json).tap { |resp|
        handle_response_errors(resp)
        @body = resp.body
      }
    rescue Excon::Error => e
      re_raise_error(endpoint, e, {})
    end

    def response_body
      @response_body ||= JSON.parse(@body, symbolize_names: true)
    end

    private

    # If this is set using a constant, and the gem is included in a project
    # that uses the dotenv gem, then it will always fall through to the default
    # unless dotenv is included and required before this gem is loaded.
    def api_url
      ENV.fetch('GLIMR_API_URL',
                'https://glimr-api.taxtribunals.dsd.io/Live_API/api/tdsapi')
    end

    # Only timeouts and network issues raise errors.
    def handle_response_errors(resp)
      if resp.status.equal?(404) && endpoint.eql?('/requestpayablecasefees')
        raise CaseNotFound, resp.status
      elsif (400..599).cover?(resp.status)
        re_raise_error(endpoint, resp.status, resp.body)
      end
    end

    def re_raise_error(docpath, e, body = nil)
      body = {} unless body.instance_of?(Hash)
      error = body.fetch(:message, e)
      case docpath
      when '/paymenttaken'
        raise PaymentNotificationFailure, error
      when '/registernewcase'
        raise RegisterNewCaseFailure, error
      else
        raise Unavailable, error
      end
    end

    def client(uri)
      Excon.new(
        uri,
        headers: {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        },
      persistent: true
      )
    end
  end
end
