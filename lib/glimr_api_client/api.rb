require 'excon'
require 'active_support'
require 'active_support/core_ext/object/to_query'

module GlimrApiClient
  module Api
    DEFAULT_ENDPOINT =
      ENV.fetch(
        'GLIMR_API_URL',
        'https://glimr-api.taxtribunals.dsd.io/Live_API/api/tdsapi'
    )

    def post
      client("#{DEFAULT_ENDPOINT}#{endpoint}").post(body: request_body.to_query).tap { |resp|
        # Only timeouts and network issues raise errors.
        handle_response_errors(resp)
        @body = resp.body
      }
    rescue Excon::Error => e
      re_raise_error(endpoint, e)
    end

    def response_body
      @response_body ||= JSON.parse(@body, symbolize_names: true)
    end

    private

    def handle_response_errors(resp)
      if (!endpoint.eql?('/paymenttaken') && resp.status.equal?(404))
        raise CaseNotFound, resp.status
      elsif (400..599).cover?(resp.status)
        re_raise_error(endpoint, resp.status)
      end
    end

    def re_raise_error(docpath, e)
      case docpath
      when '/paymenttaken'
        raise PaymentNotificationFailure, e
      when '/registernewcase'
        raise RegisterNewCaseFailure, e
      else
        raise Unavailable, e
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
