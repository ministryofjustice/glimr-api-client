require 'spec_helper'

RSpec.describe GlimrApiClient::Update do
  let(:params) {
    {
      feeLiabilityId: 12345,
      paymentReference: 12345,
      govpayReference: 12345,
      paidAmountInPence: 2000
    }
  }

  let(:body) { {} }

  before do
    stub_request(:post, /paymenttaken/).to_return(status: 200, body: body.to_json)
  end

  describe '#endpoint' do
    specify {
      # Quick-n-dirty mutant kill.
      expect(described_class.new(params).send(:endpoint)).to eq('/paymenttaken')
    }
  end

  it 'raises an error when a fee object is not supplied' do
    expect { described_class.call }.to raise_error(ArgumentError)
  end

  describe '#request_body' do
    context 'when feeLiabilityId is missing' do
      before do
        params.delete(:feeLiabilityId)
      end

      it 'raises an error' do
        expect { described_class.call(params) }.to raise_error(GlimrApiClient::RequestError, '[:feeLiabilityId]')
      end
    end

    context 'when paymentReference is missing' do
      before do
        params.delete(:paymentReference)
      end

      it 'raises an error' do
        expect { described_class.call(params) }.to raise_error(GlimrApiClient::RequestError, '[:paymentReference]')
      end
    end

    context 'when govpayReference is missing' do
      before do
        params.delete(:govpayReference)
      end

      it 'raises an error' do
        expect { described_class.call(params) }.to raise_error(GlimrApiClient::RequestError, '[:govpayReference]')
      end
    end

    context 'when paidAmountInPence is missing' do
      before do
        params.delete(:paidAmountInPence)
      end

      it 'raises an error' do
        expect { described_class.call(params) }.to raise_error(GlimrApiClient::RequestError, '[:paidAmountInPence]')
      end
    end

    it 'does not raise an error when required parameters are provided' do
      expect { described_class.call(params) }.not_to raise_error
    end
  end

  describe '#post' do
    describe '#response_body' do
      let(:body) {
        {
          feeLiabilityId: 123456789,
          feeTransactionId: 123456789,
          paidAmountInPence: 9999
        }
      }

      it 'returns the response as a hash' do
        expect(described_class.call(params).response_body).to eq(body)
      end
    end
  end

  describe '#re_raise_error' do
    let(:body) { { message: '' } }
    let(:post_response) { double(status: 404, body: body.to_json) }

    # Error codes 301 to 305 *should* be covered by the validations, so they
    # are not processed here.
    context 'error 311 - FeeLiability not found for FeeLiabilityID' do
      let(:body) { { glimrerrorcode: 311, message: 'Not found' } }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::Update::FeeLiabilityNotFound, 'Not found')
      end
    end

    # The curly-braces are taken from the GLiMR api spec and appear to
    # represent a placeholder for an arbitrary value. I'm reproducing them here
    # to make it easier to link the descriptions with the error code table in
    # the spec.
    context 'error 312 - Invalid format for PaymentReference' do
      let(:body) { { glimrerrorcode: 312, message: 'Invalid format' } }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::Update::PaymentReferenceInvalidFormat, 'Invalid format')
      end
    end

    context 'error 314 - Invalid format for GovPayReference' do
      let(:body) { { glimrerrorcode: 314, message: 'Invalid format' } }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::Update::GovPayReferenceInvalidFormat, 'Invalid format')
      end
    end

    context 'error 315 - Invalid PaidAmount' do
      let(:body) { { glimrerrorcode: 315, message: 'Invalid Amount' } }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::Update::InvalidAmount, 'Invalid Amount')
      end
    end

    # 'Equivalent to Credit Clearance suspended' according to spec.
    context 'error 321 - A payment with GovPay reference already exists' do
      let(:body) { { glimrerrorcode: 321, message: 'Payment exists' } }

      it 'raises an error' do
        expect {
          described_class.call(params)
        }.to raise_error(GlimrApiClient::Update::GovPayReferenceExistsOnSystem, 'Payment exists')
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
