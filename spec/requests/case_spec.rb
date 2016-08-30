require 'rails_helper'
require 'support/shared_examples_for_glimr'

RSpec.describe GlimrApiClient::Case do
  include_examples 'a case fee of £20 is due', 'TT/2016/00001'

  it 'requires a case reference' do
    expect{ described_class.find }.to raise_error(GlimrApiClient::Unavailable)
    expect{ described_class.new.call }.to raise_error(GlimrApiClient::Unavailable)
  end

  subject { described_class.find('TT/2016/00001') }

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
            glimrId: 7,
            description: 'Lodgement Fee',
            amount: 2000
          )
        ]
      )
    end

    it 'casts the returned values correctly' do
      expect(subject.fees.first.glimrId).to be_an_integer
      expect(subject.fees.first.description).to be_a(String)
      expect(subject.fees.first.amount).to be_an_integer
    end
  end
end
