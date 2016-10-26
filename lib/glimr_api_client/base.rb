module GlimrApiClient
  class Base
    include GlimrApiClient::Api

    def self.call(*args)
      new(*args).call
    end

    def call
      check_request!
      post
      self
    end

  end
end

