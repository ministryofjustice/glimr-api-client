class CaseRequestsController < ApplicationController
  def new
    @case_request = CaseRequest.new(nil, nil)
  end
end
