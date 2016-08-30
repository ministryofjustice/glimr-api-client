module GlimrApiClient
  class Available
    include GlimrApiClient::Api

    class << self
      delegate :call, to: :new
    end

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
      {}
    end
  end
end
