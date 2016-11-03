require 'excon'

module GlimrApiClient
  module Api
    def post
      client("#{api_url}#{endpoint}").post(body: request_body.to_json).tap { |resp|
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

    # If this is set using a constant, and the gem is included in a project
    # that uses the dotenv gem, then it will always fall through to the default
    # unless dotenv is included and required before this gem is loaded.
    def api_url
      ENV.fetch('GLIMR_API_URL',
                'https://glimr-api.taxtribunals.dsd.io/Live_API/api/tdsapi')
    end

    def handle_response_errors(resp)
      if (endpoint.eql?('/glimravailable') && resp.status.equal?(404))
        raise Unavailable, resp.status
        # if /requestpayablecasefees gives a 404, raise casenotfound
        # otherwise, re-raise whatever
      elsif (!endpoint.eql?('/paymenttaken') && resp.status.equal?(404))
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
