require 'spec_helper'
require 'support/shared_examples_for_glimr'
require 'support/shared_examples_for_generic_errors'

RSpec.describe GlimrApiClient::Case do
  let(:case_number) { 'TC/2012/00001' }
  let(:confirmation_code) { 'ABC123' }
  let(:params) {
    {
      jurisdictionId: 8,
      caseNumber: case_number,
      confirmationCode: confirmation_code
    }
  }
  let(:fees) {
    {
      jurisdictionId: 8,
      tribunalCaseId: 60_029,
      feeLiabilities:
        [
          {
            feeLiabilityId: '7',
           caseTitle: 'First Title',
           onlineFeeTypeDescription: 'Lodgement Fee',
           payableWithUnclearedInPence: '2000'
          },
          { feeLiabilityId: '7',
            caseTitle: 'Second Title',
            onlineFeeTypeDescription: 'Another Fee',
            payableWithUnclearedInPence: '2000'
          }
        ]
    }
  }

  let(:post_response) { double(status: 200, body: '') }
  let(:excon) { class_double(Excon, post: post_response) }

  before do
    allow_any_instance_of(described_class).to receive(:client).and_return(excon)
  end

  it 'raises an error when no parameters are supplied' do
    expect { described_class.find }.to raise_error(ArgumentError)
  end

  describe '#endpoint' do
    specify {
      # Quick-n-dirty mutant kill.
      expect(described_class.new(case_number, confirmation_code).send(:endpoint)).to eq('/requestcasefees')
    }
  end

  describe '#post' do
    it 'passes all the parameters to glimr' do
      post_params = { body: params.to_json }
      expect(excon).to receive(:post).with(post_params)
      described_class.find(case_number, confirmation_code)
    end
  end

  context 'errors' do
    let(:body) { { message: '' } }
    let(:post_response) { double(status: 404, body: body.to_json) }

    # The curly-braces are taken from the GLiMR api spec and appear to
    # represent a placeholder for an arbitrary value. I'm reproducing them here
    # to make it easier to link the descriptions with the error code table in
    # the spec.
    describe 'error 212 - TribunalCase for CaseNumber {0} not found' do
      let(:body) {
        {
          glimrerrorcode: 212,
          # Truncated for brevity
          message: 'TribunalCase not found'
        }
      }

      it 'raises an error' do
        expect {
          described_class.find(case_number, confirmation_code)
        }.to raise_error(GlimrApiClient::Case::NotFound, 'TribunalCase not found')
      end
    end

    describe 'error 213 - Invalid CaseNumber/CaseConfirmationCode combination {0} / {1}' do
      let(:body) {
        {
          glimrerrorcode: 213,
          # Truncated for brevity
          message: 'Invalid CaseNumber'
        }
      }

      it 'raises an error' do
        expect {
          described_class.find(case_number, confirmation_code)
        }.to raise_error(GlimrApiClient::Case::InvalidCaseNumber, 'Invalid CaseNumber')
      end
    end

    # TODO: DRY this out.  Needs case to respond to `#call(params)` directly.
    # Once that is done, these can be replaced with the shared examples.
    describe 'Unspecified error' do
      let(:body) {
        {
          message: 'Kaboom'
        }
      }

      it 'raises an Unavailable error' do
        expect {
          described_class.find(case_number, confirmation_code)
        }.to raise_error(GlimrApiClient::Unavailable, 'Kaboom')
      end
    end

    describe 'Missing error message' do
      let(:body) {{}}

      it 'raises an Unavailable error' do
        expect {
          described_class.find(case_number, confirmation_code)
        }.to raise_error(GlimrApiClient::Unavailable)
      end
    end
  end
end

RSpec.describe GlimrApiClient::Case do
  include_examples 'no fees', 'TT/2016/00001', 'ABC123'

  subject { described_class.find('TT/2016/00001', 'ABC123') }

  it 'returns "Missing Title" when there are no fees' do
    expect(subject.title).to eq('Missing Title')
  end
end

RSpec.describe GlimrApiClient::Case do
  include_examples 'two fees', 'TT/2016/00001', 'ABC123'

  subject { described_class.find('TT/2016/00001', 'ABC123') }

  it 'returns the title from the first fee' do
    expect(subject.title).to eq('First Title')
  end
end

RSpec.describe GlimrApiClient::Case do
  include_examples 'a case fee of £20 is due', 'TT/2016/00001', 'ABC123'

  it 'requires two parameters' do
    expect{ described_class.find }.to raise_error(ArgumentError)
    expect{ described_class.find('something') }.to raise_error(ArgumentError)
  end

  subject { described_class.find('TT/2016/00001', 'ABC123') }

  it 'returns the title' do
    expect(subject.title).to eq('You vs HM Revenue & Customs')
  end

  describe '#fees' do
    it 'returns a collection of fee objects' do
      expect(subject.fees).to eq(
        [
          OpenStruct.new(
            glimr_id: 7,
            description: 'Lodgement Fee',
            amount: 2000,
            case_title: 'You vs HM Revenue & Customs'
          )
        ]
      )
    end

    it 'casts the returned values correctly' do
      expect(subject.fees.first.glimr_id).to be_an_integer
      expect(subject.fees.first.description).to be_a(String)
      expect(subject.fees.first.amount).to be_an_integer
    end
  end

  context 'new specs' do
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
    let(:excon) { class_double(Excon, post: post_response) }

    before do
      allow_any_instance_of(described_class).to receive(:client).and_return(excon)
    end

    describe '#endpoint' do
      specify {
        # Quick-n-dirty mutant kill.
        expect(described_class.new(tax_tribunal_reference, confirmation_code).send(:endpoint)).to eq('/requestcasefees')
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

    describe '#post' do
      let(:params) { {
        jurisdictionId: GlimrApiClient::Case::TRIBUNAL_JURISDICTION_ID,
        caseNumber: tax_tribunal_reference,
        confirmationCode: confirmation_code
      } }

      it 'passes all the parameters to glimr' do
        post_params = { body: params.to_json }
        expect(excon).to receive(:post).with(post_params)
        described_class.find(tax_tribunal_reference, confirmation_code)
      end

      describe '#response_body' do
        it 'returns the response as a hash' do
          expect(described_class.find(tax_tribunal_reference, confirmation_code).response_body).to eq(response)
        end
      end
    end

    describe 'Case title' do
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
      context 'when there are paid and unpaid fee liabilities' do
        let(:fees) { [ unpaid_fee_20, unpaid_fee_50, paid_fee ] }

        it 'returns the unpaid liabilities' do
          resp = described_class.find(tax_tribunal_reference, confirmation_code)
          expect(resp.fees.map(&:amount)).to eq([1, 5000])
        end
      end
    end
  end
end

