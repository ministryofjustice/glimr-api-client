require 'json'
require 'glimr_api_client/version'
require 'glimr_api_client/api'
require 'glimr_api_client/base'
require 'glimr_api_client/available'
require 'glimr_api_client/case'
require 'glimr_api_client/update'
require 'glimr_api_client/register_new_case'
require 'glimr_api_client/pay_by_account'


module GlimrApiClient
  class PaymentNotificationFailure < StandardError; end
  class RegisterNewCaseFailure < StandardError; end
  class Unavailable < StandardError; end
  class CaseNotFound < StandardError; end
  class RequestError < StandardError; end;
  class FeeLiabilityNotFound < StandardError; end;
  class PBAAccountNotFound < StandardError; end;
  # This *could* be more specific, but is already excessively long...
  class InvalidPBAAccountAndConfirmation < StandardError; end;
  class PBAInvalidAmount < StandardError; end;
  class PBAGlobalStatusInactive < StandardError; end;
  class PBAJurisdictionStatusInactive < StandardError; end;
  class PBAUnspecifiedError < StandardError; end;
end
