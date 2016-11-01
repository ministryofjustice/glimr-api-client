module GlimrApiClient
  class Available
    include GlimrApiClient::Api
    extend SingleForwardable

    def_delegator :new, :call

    def call
      post
      self
    end

    def available?
      response_body.fetch(:glimrAvailable).eql?('yes').tap { |status|
        if status.equal?(false)
          raise Unavailable
        end
      }
    end

    private

    def endpoint
      '/glimravailable'
    end

    def request_body
    end
  end
end
