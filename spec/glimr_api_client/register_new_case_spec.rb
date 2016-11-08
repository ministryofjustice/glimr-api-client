require 'rails_helper'

RSpec.describe GlimrApiClient::RegisterNewCase do
  let(:params) { {} }
  let(:post_response) { double(status: 200, body: {}) }
  let(:excon) { class_double(Excon, post: post_response) }
  let(:api) { described_class.new(params) }

  before do
    allow_any_instance_of(described_class).to receive(:client).and_return(excon)
  end

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
      expect { described_class.call(valid_params) }.not_to raise_error
    end
  end

  context 'when all parameters are provided' do
    let(:params) { {
      jurisdictionId: 8,
      onlineMappingCode: 'something',
      contactPhone: '1234',
      contactFax: '5678',
      contactEmail: 'foo_at_bar.com',
      contactPreference: 'Email',
      contactFirstName: 'Alice',
      contactLastName: 'Caroll',
      contactStreet1: '5_Wonderstreet',
      contactStreet2: 'contact_street_2',
      contactStreet3: 'contact_street_3',
      contactStreet4: 'contact_street_4',
      contactCity: 'London',
      documentsURL: 'http...google.com',
      repPhone: '7890',
      repFax: '6789',
      repEmail: 'bar_at_baz.com',
      repPreference: 'Fax',
      repReference: 'MYREF',
      repIsAuthorised: 'Yes',
      repOrganisationName: 'Acme._Ltd.',
      repFAO: 'Bob_Hope',
      repStreet1: '5_Repstreet',
      repStreet2: 'Repton',
      repStreet3: 'Repshire',
      repStreet4: 'Rep_st._4',
      repCity: 'City_of_reps'
    } }

    it 'posts all the parameters to glimr' do
      post_params = { body: params.to_json }
      expect(excon).to receive(:post).with(post_params)
      api.call
    end
  end

  context 'errors' do
    let(:params) { { jurisdictionId: 8, onlineMappingCode: 'something' } }
    let(:body) { { message: '' } }
    let(:post_response) { double(status: 404, body: body.to_json) }

    # are not processed here.
    describe 'error 411 - Jurisdiction not found' do
      let(:body) {
        {
          glimrerrorcode: 411,
          # Truncated for brevity
          message: 'Not found'
        }
      }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::RegisterNewCase::JurisdictionNotFound, 'Not found')
      end
    end

    describe 'error 412 - Online Mapping not found' do
      let(:body) {
        {
          glimrerrorcode: 412,
          # Truncated for brevity
          message: 'Not found'
        }
      }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::RegisterNewCase::OnlineMappingNotFoundOrInvalid, 'Not found')
      end
    end

    describe 'error 421 - CaseCreationFailed' do
      let(:body) {
        {
          glimrerrorcode: 421,
          # Truncated for brevity
          message: 'Failed'
        }
      }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::RegisterNewCase::CaseCreationFailed, 'Failed')
      end
    end

    describe 'Unspecified error' do
      let(:body) {
        {
          message: 'Kaboom'
        }
      }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::Unavailable, 'Kaboom')
      end
    end
  end
end
