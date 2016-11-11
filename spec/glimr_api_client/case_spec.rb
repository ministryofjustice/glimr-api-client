require 'spec_helper'
require 'support/shared_examples_for_glimr'

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
end
