require 'rails_helper'
require 'support/shared_examples_for_glimr'

RSpec.describe GlimrApiClient::Case do
  include_examples 'no fees', 'TT/2016/00001', 'ABC123'

  subject { described_class.find('TT/2016/00001', 'ABC123') }

  describe '#title' do
    it 'returns the title' do
      expect(subject.title).to eq('Missing Title')
    end
  end
end

RSpec.describe GlimrApiClient::Case do
  include_examples 'two fees', 'TT/2016/00001', 'ABC123'

  subject { described_class.find('TT/2016/00001', 'ABC123') }

  describe '#title' do
    it 'returns the title from the first fee' do
      expect(subject.title).to eq('First Title')
    end
  end
end

RSpec.describe GlimrApiClient::Case do
  include_examples 'a case fee of £20 is due', 'TT/2016/00001', 'ABC123'

  it 'requires two parameters' do
    expect{ described_class.find }.to raise_error(ArgumentError)
    expect{ described_class.find('something') }.to raise_error(ArgumentError)
  end

  subject { described_class.find('TT/2016/00001', 'ABC123') }

  describe '#title' do
    it 'returns the title' do
      expect(subject.title).to eq('You vs HM Revenue & Customs')
    end
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
