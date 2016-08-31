require 'glimr_api_client/railtie' if defined?(Rails)
require 'glimr_api_client/version'
require 'glimr_api_client/api'
require 'glimr_api_client/available'
require 'glimr_api_client/case'
require 'glimr_api_client/update'


module GlimrApiClient
  class PaymentNotificationFailure < StandardError; end
  class Unavailable < StandardError; end
  class CaseNotFound < StandardError; end
  class RequestError < StandardError; end;
end
