require 'json'
require 'glimr_api_client/version'
require 'glimr_api_client/api'
require 'glimr_api_client/base'
require 'glimr_api_client/find_case'
require 'glimr_api_client/hwf_requested'
require 'glimr_api_client/pay_by_account'
require 'glimr_api_client/available'
require 'glimr_api_client/register_new_case'

module GlimrApiClient
  class RegisterNewCaseFailure < StandardError; end
  class Unavailable < StandardError; end
  class CaseNotFound < StandardError; end
  class RequestError < StandardError; end;
end
