require 'spec_helper'

RSpec.describe GlimrApiClient::RegisterNewCase do
  let(:params) { {} }
  let(:post_response) { double(status: 200, body: {}) }
  let(:rest_client) { double.as_null_object }
  let(:api) { described_class.new(params) }

  describe '#endpoint' do
    specify {
      # Quick-n-dirty mutant kill.
      expect(described_class.new(params).send(:endpoint)).to eq('/registernewcase')
    }
  end

  context 'validating parameters' do
    let(:valid_params) { { jurisdictionId: 8, onlineMappingCode: 'something' } }

    it 'raises an error when no parameters are supplied' do
      expect { described_class.call }.to raise_error(ArgumentError)
    end

    context 'when onlineMappingCode is missing' do
      let(:params) { { jurisdictionId: 8 } }

      it 'raises an error' do
        expect { described_class.call(params) }.to raise_error(GlimrApiClient::RequestError, '[:onlineMappingCode]')
      end
    end

    context 'when jurisdictionId is missing' do
      let(:params) { { onlineMappingCode: 'something' } }

      it 'raises an error' do
        expect { described_class.call(params) }.to raise_error(GlimrApiClient::RequestError, '[:jurisdictionId]')
      end
    end

    it 'does not raise an error when required parameters are provided' do
      stub_request(:post, /glimr/).to_return(status: 200, body: {response: 'repsonse'}.to_json)
      expect { described_class.call(valid_params) }.not_to raise_error
    end
  end

  describe '#re_raise_error' do
    let(:params) { { jurisdictionId: 8, onlineMappingCode: 'something' } }
    let(:body) { { message: '' } }

    before do
      stub_request(:post, /glimr/).to_return(status: 200, body: body.to_json)
    end

    # are not processed here.
    context 'error 411 - Jurisdiction not found' do
      let(:body) { { glimrerrorcode: 411, message: 'Not found' } }

      it 'raises JurisdictionNotFound' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::RegisterNewCase::JurisdictionNotFound, 'Not found')
      end
    end

    context 'error 412 - Online Mapping not found' do
      let(:body) { { glimrerrorcode: 412, message: 'Not found' } }

      it 'raises OnlineMappingNotFoundOrInvalid' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::RegisterNewCase::OnlineMappingNotFoundOrInvalid, 'Not found')
      end
    end

    context 'error 421 - CaseCreationFailed' do
      let(:body) { { glimrerrorcode: 421, message: 'Failed' } }

      it 'raises CaseCreationFailed' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::RegisterNewCase::CaseCreationFailed, 'Failed')
      end
    end

    context 'unknown glimr error' do
      let(:body) { { glimrerrorcode: 5_000, message: 'Boom' } }

      it 'raises Unavailable with the error message' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::Unavailable, 'Boom')
      end
    end
  end
end
