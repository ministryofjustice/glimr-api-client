require 'rails_helper'
require 'support/shared_examples_for_glimr'

RSpec.describe GlimrApiClient::RegisterNewCase do
  include_examples 'register new case with glimr'

  subject(:reg) { described_class.new(params) }

  context "when required parameters are missing" do
    let(:params) { {} }
    specify { expect { reg.call }.to raise_error(GlimrApiClient::RequestError) }
  end

  context "when required parameters are provided" do
    let(:params) { { jurisdictionId: 8, onlineMappingCode: 'something' } }
    specify { expect { reg.call }.not_to raise_error }
  end
end
