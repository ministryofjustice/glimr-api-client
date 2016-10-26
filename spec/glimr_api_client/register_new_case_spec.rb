require 'rails_helper'
require 'support/shared_examples_for_glimr'

RSpec.describe GlimrApiClient::RegisterNewCase do
  include_examples 'register new case with glimr'

  let(:params) { {} }
  let(:excon) { class_double(Excon, post: double(status: 200, body: '')) }
  let(:api) { described_class.new(params) }

  before do
    allow(api).to receive(:client).and_return(excon)
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

    it 'does not barf when required parameters are provided' do
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
      querystring = params.keys.sort.collect {|k| [k, params[k]].join('=')}.join('&')
      post_params = { body: querystring }
      expect(excon).to receive(:post).with(post_params)
      api.call
    end
  end

  context 'when excon post fails' do
    let(:params) { { jurisdictionId: 8, onlineMappingCode: 'something' } }

    before do
      allow(excon).to receive(:post).and_raise(Excon::Error, 'kaboom')
    end

    it 're-raises the error' do
      expect { api.call }.to raise_error(GlimrApiClient::RegisterNewCaseFailure, 'kaboom')
    end
  end
end
