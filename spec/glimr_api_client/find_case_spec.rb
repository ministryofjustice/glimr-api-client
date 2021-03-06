require 'spec_helper'

RSpec.describe GlimrApiClient::FindCase do
  let(:tax_tribunal_reference) { 'TC/2012/00001' }
  let(:confirmation_code) { 'ABC123' }

  let(:title1) { 'First Case Title' }
  let(:title2) { 'Second Case Title' }
  let(:title_paid) { 'All Paid Case Title' }

  let(:unpaid_fee_20) {
    {
      feeLiabilityId: '7',
      caseTitle: title1,
      onlineFeeTypeDescription: 'Lodgement Fee',
      payableWithUnclearedInPence: '1'  # <- 1 rather than 2000 to keep mutant happy
    }
  }

  let(:unpaid_fee_50) {
    {
      feeLiabilityId: '7',
      caseTitle: title2,
      onlineFeeTypeDescription: 'Lodgement Fee',
      payableWithUnclearedInPence: '5000'
    }
  }

  let(:paid_fee) {
    {
      feeLiabilityId: '7',
      caseTitle: title_paid,
      onlineFeeTypeDescription: 'Lodgement Fee',
      payableWithUnclearedInPence: '0'
    }
  }

  let(:paid_fee2) {
    paid_fee.merge(caseTitle: 'Second Paid Title')
  }

  let(:fees) { [ unpaid_fee_20 ] }

  let(:response) {
    {
      jurisdictionId: 8,
      tribunalCaseId: 60_029,
      feeLiabilities: fees
    }
  }

  let(:post_response) { double(status: 200, body: response.to_json) }
  let(:rest_client) { double.as_null_object }

  before do
    stub_request(:post, /glimr/).to_return(status: 200, body: response.to_json)
  end

  describe '.find' do
    let(:inst) { instance_double(described_class, call: true) }

    it 'passes all arguments on to the instance method' do
      expect(described_class).to receive(:new).with('ABC', 123).and_return(inst)
      described_class.find('ABC', 123)
    end

    it 'delegates to #call on the instance' do
      allow(described_class).to receive(:new).and_return(inst)
      expect(inst).to receive(:call)
      described_class.find('ABC', 123)
    end
  end

  describe '#endpoint' do
    specify {
      # Quick-n-dirty mutant kill.
      expect(described_class.new(tax_tribunal_reference, confirmation_code).send(:endpoint)).to eq('/requestcasefees')
    }
  end

  describe '#request_body' do
    specify {
      # Quick-n-dirty mutant kill. Without this, mutant claims that replacing Case#request_body with an empty
      # method does not cause the specs to fail. This is not true, but something to do with the way mutant
      # chooses specs to run seems to be broken
      expect(described_class.new(1234, 1234).send(:request_body)).to eq({ jurisdictionId: 8, caseNumber: 1234, confirmationCode: 1234 })
    }
  end

  describe '#request_body' do

    it 'raises an error when no parameters are supplied' do
      expect { described_class.find }.to raise_error(ArgumentError)
    end

    it 'does not raise an error when two parameters are provided' do
      expect { described_class.find('a', 'b') }.not_to raise_error
    end
  end

  describe 'Case title' do
    context 'when there are no fees' do
      let(:fees) { [] }

      it 'returns "Missing Title"' do
        resp = described_class.find(tax_tribunal_reference, confirmation_code)
        expect(resp.title).to eq('Missing Title')
      end
    end

    context 'when there is one unpaid fee liability' do
      let(:fees) { [ unpaid_fee_20 ] }

      it 'gets the case title from the fee liability' do
        resp = described_class.find(tax_tribunal_reference, confirmation_code)
        expect(resp.title).to eq(title1)
      end

    end

    context 'when there are two unpaid fee liabilities' do
      let(:fees) { [ unpaid_fee_20, unpaid_fee_50 ] }

      it 'gets the case title from the first fee liability' do
        resp = described_class.find(tax_tribunal_reference, confirmation_code)
        expect(resp.title).to eq(title1)
      end
    end

    context 'when there is one paid and one unpaid fee liabilities' do
      let(:fees) { [ paid_fee, unpaid_fee_20 ] }

      it 'gets the case title from the first unpaid fee liability' do
        resp = described_class.find(tax_tribunal_reference, confirmation_code)
        expect(resp.title).to eq(title1)
      end
    end

    context 'when there are two paid fee liabilities' do
      let(:fees) { [ paid_fee, paid_fee2 ] }

      it 'gets the case title from the paid fee liability' do
        resp = described_class.find(tax_tribunal_reference, confirmation_code)
        expect(resp.title).to eq(title_paid)
      end
    end
  end

  describe '#fees' do
    subject { described_class.find(tax_tribunal_reference, confirmation_code) }

    context 'when there are paid and unpaid fee liabilities' do
      let(:fees) { [ unpaid_fee_20, unpaid_fee_50, paid_fee ] }

      it 'returns the unpaid liabilities' do
        expect(subject.fees.map(&:amount)).to eq([1, 5000])
      end
    end

    it 'returns a collection of fee objects' do
      expect(subject.fees).to eq(
        [
          OpenStruct.new(
            glimr_id: 7,
            description: 'Lodgement Fee',
            amount: 1,
            case_title: title1
          )
        ]
      )
    end

    it 'casts the returned values correctly' do
      fee = subject.fees.first
      expect(fee.glimr_id).to be_an_integer
      expect(fee.description).to be_a(String)
      expect(fee.amount).to be_an_integer
    end
  end

  context '#re_raise_error' do
    let(:body) { { message: '' } }

    before do
      stub_request(:post, /glimr/).to_return(status: 200, body: body.to_json)
    end

    # The curly-braces are taken from the GLiMR api spec and appear to
    # represent a placeholder for an arbitrary value. I'm reproducing them here
    # to make it easier to link the descriptions with the error code table in
    # the spec.
    describe 'error 212 - TribunalCase for CaseNumber {0} not found' do
      let(:body) { { glimrerrorcode: 212, message: 'TribunalCase not found' } }

      it 'raises an error' do
        expect {
          described_class.find(tax_tribunal_reference, confirmation_code)
        }.to raise_error(GlimrApiClient::FindCase::NotFound, 'TribunalCase not found')
      end
    end

    describe 'error 213 - Invalid CaseNumber/CaseConfirmationCode combination {0} / {1}' do
      let(:body) { { glimrerrorcode: 213, message: 'Invalid CaseNumber' } }

      it 'raises an error' do
        expect {
          described_class.find(tax_tribunal_reference, confirmation_code)
        }.to raise_error(GlimrApiClient::FindCase::InvalidCaseNumber, 'Invalid CaseNumber')
      end
    end

    context 'unknown glimr error' do
      let(:body) { { glimrerrorcode: 5_000, message: 'Boom' } }

      it 'raises Unavailable with the error message' do
        expect {
          described_class.find(tax_tribunal_reference, confirmation_code)
        }.to raise_error(GlimrApiClient::Unavailable, 'Boom')
      end
    end
  end
end
