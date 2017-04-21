require 'typhoeus'

module GlimrApiClient
  module Api
    attr_reader :response_body

    # Showing the GLiMR post & response in the container logs is helpful
    # for troubleshooting in the staging environment (when we are using
    # the websocket link to communicate with a GLiMR instance to which
    # we have very limited access.
    # DO NOT SET THIS ENV VAR IN PRODUCTION - we should not be logging
    # this sensitive user data from the live service.
    def post
      @response_body = make_request("#{api_url}#{endpoint}", request_body)
      puts "GLIMR POST: #{endpoint} - #{request_body.to_json}" if ENV.key?('GLIMR_API_DEBUG')
    end

    def timeout
      Integer(ENV.fetch('GLIMR_API_TIMEOUT_SECONDS', 5))
    end

    private

    # This uses the REST response body instead of a simple error string in
    # order to provide a consistent interface for raising errors.  GLiMR errors
    # are indicated by a successful response that has the `:glimrerrorcode` key
    # set. See `::RegisterNewCase` for an example.
    def re_raise_error(body)
      raise Unavailable, body.fetch(:message)
    end

    def parse_response(response_body)
      JSON.parse(response_body, symbolize_names: true).tap { |body|
        # These are required because GLiMR can return errors in an otherwise
        # successful response.
        re_raise_error(body) if body.key?(:glimrerrorcode)
        # `:message` is only returned if there is an error  This *shouldn't*
        # happen as all errors should have both `:glimrerrorcode` and
        # `:message`...
        re_raise_error(body) if body.key?(:message)
      }
    end

    # If this is set using a constant, and the gem is included in a project
    # that uses the dotenv gem, then it will always fall through to the default
    # unless dotenv is included and required before this gem is loaded.
    def api_url
      ENV.fetch('GLIMR_API_URL',
                'https://glimr-api.taxtribunals.dsd.io/Live_API/api/tdsapi')
    end

    def make_request(endpoint, body)
      response_body = nil
      request = client(endpoint, body)

      request.on_complete do |response|
        if response.success?
          body = response.body
          puts "GLIMR RESPONSE: #{body}" if ENV.key?('GLIMR_API_DEBUG')
          response_body = parse_response(body)
        elsif response.timed_out?
          re_raise_error(message: 'timed out')
        elsif (400..599).cover?(response.code)
          re_raise_error(message: response.code)
        end
      end

      request.run
      response_body
    end

    def client(uri, body)
      Typhoeus::Request.new(
        uri,
        method: :post,
        body: body,
        headers: {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      },
      timeout: timeout
      )
    end
  end
end
