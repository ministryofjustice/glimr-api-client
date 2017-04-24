require 'spec_helper'

RSpec.describe GlimrApiClient::HwfRequested do
  let(:params) {
    {
      feeLiabilityId: 123456789,
      hwfRequestReference: 'l7w64bst84jwy',
      amountToPayInPence: 9999
    }
  }

  let(:body) { {} }

  before do
    stub_request(:post, /hwfrequested/).to_return(status: 200, body: body.to_json)
  end

  describe '#endpoint' do
    specify {
      # Quick-n-dirty mutant kill.
      expect(described_class.new(params).send(:endpoint)).to eq('/hwfrequested')
    }
  end

  describe '#request_body' do
    it 'raises an error when no parameters are supplied' do
      expect { described_class.call }.to raise_error(ArgumentError)
    end

    context 'when feeLiabilityId is missing' do
      before do
        params.delete(:feeLiabilityId)
      end

      it 'raises an error' do
        expect { described_class.call(params) }.to raise_error(GlimrApiClient::RequestError, '[:feeLiabilityId]')
      end
    end

    context 'when hwfRequestReference is missing' do
      before do
        params.delete(:hwfRequestReference)
      end

      it 'raises an error' do
        expect { described_class.call(params) }.to raise_error(GlimrApiClient::RequestError, '[:hwfRequestReference]')
      end
    end

    it 'does not raise an error when required parameters are provided' do
      expect { described_class.call(params) }.not_to raise_error
    end
  end

  describe '#re_raise_error' do
    let(:body) { { message: '' } }

    before do
      stub_request(:post, /hwfrequested/).to_return(status: 200, body: body.to_json)
    end

    # Error codes 601 to 603 *should* be covered by the validations, so they
    # are not processed here.
    context 'error 611 - FeeLiability not found for FeeLiabilityID' do
      let(:body) { { glimrerrorcode: 611, message: 'Not found' } }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::HwfRequested::FeeLiabilityNotFound, 'Not found')
      end
    end

    context 'error 612 - Invalid AmountToPay {0}' do
      let(:body) { { glimrerrorcode: 612, message: 'Invalid Amount' } }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::HwfRequested::InvalidAmount, 'Invalid Amount')
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
