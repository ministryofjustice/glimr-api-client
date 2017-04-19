require 'excon'

module GlimrApiClient
  module Api
    # Showing the GLiMR post & response in the container logs is helpful
    # for troubleshooting in the staging environment (when we are using
    # the websocket link to communicate with a GLiMR instance to which
    # we have very limited access.
    # DO NOT SET THIS ENV VAR IN PRODUCTION - we should not be logging
    # this sensitive user data from the live service.
    def post
      puts "GLIMR POST: #{endpoint} - #{request_body.to_json}" if ENV.key?('GLIMR_API_DEBUG')
      client("#{api_url}#{endpoint}").post(body: request_body.to_json).tap { |resp|
        handle_response_errors(resp) if (400..599).cover?(resp.status)
        puts "GLIMR RESPONSE: #{resp.body}" if ENV.key?('GLIMR_API_DEBUG')
        @body = resp.body
      }
    rescue Excon::Error => e
      re_raise_error(message: e)
    end

    def response_body
      @response_body ||= JSON.parse(@body, symbolize_names: true)
    end

    def timeout
      Integer(ENV.fetch('GLIMR_API_TIMEOUT_SECONDS', 5))
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
      # TODO: log error as well.
      # Deal with cases where we get an otherwise unparseable response body.
      body = begin
               JSON.parse(resp.body, symbolize_names: true)
             rescue JSON::ParserError
               { message: resp.status }
             end
      re_raise_error(body)
    end

    def re_raise_error(body)
      error = body.fetch(:message)
      raise Unavailable, error
    end

    def client(uri)
      Excon.new(
        uri,
        headers: {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        },
        persistent: true,
        write_timeout: timeout,
        connection_timeout: timeout,
      )
    end
  end
end
