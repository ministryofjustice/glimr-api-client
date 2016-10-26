module GlimrApiClient
  class RegisterNewCase < Base
    def initialize(params)
      @params = params
    end

    private

    def check_request!
      errors = []
      [
        :jurisdictionId,
        :onlineMappingCode
      ].each do |required|
        errors << required if request_body.fetch(required).blank?
      end
      raise RequestError, errors unless errors.blank?
    end

    def endpoint
      '/registernewcase'
    end

    def request_body
      {
        contactPhone: @params[:contactPhone],
        contactFax: @params[:contactFax],
        contactEmail: @params[:contactEmail],
        contactPreference: @params[:contactPreference],
        contactFirstName: @params[:contactFirstName],
        contactLastName: @params[:contactLastName],
        contactStreet1: @params[:contactStreet1],
        contactStreet2: @params[:contactStreet2],
        contactStreet3: @params[:contactStreet3],
        contactStreet4: @params[:contactStreet4],
        contactCity: @params[:contactCity],
        jurisdictionId: @params[:jurisdictionId],
        onlineMappingCode: @params[:onlineMappingCode],
        documentsURL: @params[:documentsURL],
        repPhone: @params[:repPhone],
        repFax: @params[:repFax],
        repEmail: @params[:repEmail],
        repPreference: @params[:repPreference],
        repReference: @params[:repReference],
        repIsAuthorised: @params[:repIsAuthorised],
        repOrganisationName: @params[:repOrganisationName],
        repFAO: @params[:repFAO],
        repStreet1: @params[:repStreet1],
        repStreet2: @params[:repStreet2],
        repStreet3: @params[:repStreet3],
        repStreet4: @params[:repStreet4],
        repCity: @params[:repCity]
      }
    end
  end
end
