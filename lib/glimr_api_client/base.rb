module GlimrApiClient
  class Base
    include GlimrApiClient::Api
    attr_reader :args

    def self.call(*args)
      new(*args).call
    end

    def initialize(*args)
      @args = args
    end

    def call
      check_request!
      post
      self
    end

    def check_request!
    end
  end
end

