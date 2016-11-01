require 'rails_helper'
require 'support/shared_examples_for_glimr'

RSpec.describe GlimrApiClient::Update do
  subject { described_class.call(fee) }

  include_examples 'report payment taken to glimr',
      # The excon stub is sensitive to the ordering of the request body order.
      { feeLiabilityId: 12345,
      paymentReference: 'ref123',
      govpayReference: '123ABC',
      paidAmountInPence: 2000 }.to_json

  let(:fee) {
    Fee.create(
      case_title: 'You vs HM Revenue & Customs',
      description: 'Lodgement Fee',
      amount: 2000,
      glimr_id: 12345,
      govpay_reference: 'ref123',
      govpay_payment_id: '123ABC'
    )
  }

  it 'requires a fee' do
    expect{ described_class.call }.to raise_error(ArgumentError)
    expect{ subject }.not_to raise_error
  end

  it 'allows access to the response_body' do
    # Because it doesn't have a specific accessor for the response data.
    expect(subject.response_body).not_to be_blank
  end

  it 'complains if the amount is missing' do
    fee.update_column(:amount, nil)
    expect{ described_class.call(fee) }.
      to raise_error(GlimrApiClient::RequestError, /paidAmountInPence/i)
  end

  it 'complains if the glimr_id is missing' do
    fee.update_column(:glimr_id, nil)
    expect{ described_class.call(fee) }.
      to raise_error(GlimrApiClient::RequestError, /feeLiabilityId/i)
  end

  it 'complains if the govpay_payment_id is missing' do
    fee.update_column(:govpay_payment_id, nil)
    expect{ described_class.call(fee) }.
      to raise_error(GlimrApiClient::RequestError, /govpayReference/i)
  end

  it 'complains if the govpay_reference is missing' do
    fee.update_column(:govpay_reference, nil)
    expect{ described_class.call(fee) }.
      to raise_error(GlimrApiClient::RequestError, /paymentReference/i)
  end
end
