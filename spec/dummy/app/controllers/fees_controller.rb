class FeesController < ApplicationController
  def new
    @dummy_fee =
      Fee.new(
        case_title: 'You vs HM Revenue & Customs',
        description: 'Lodgement Fee',
        amount: 2000,
        glimr_id: 12345,
        govpay_reference: 'ref123',
        govpay_payment_id: '123ABC'
    )
  end

  def create
    @dummy_fee = Fee.new(fee_params)
    if @dummy_fee.save!
      GlimrApiClient::Update.call(@dummy_fee)
      render 'show'
    end
  end

  private

  def fee_params
    params.
      require(:fee).
        permit(
          :case_title,
          :desciption,
          :amount,
          :glimr_id,
          :govpay_payment_id,
          :govpay_reference
        )
  end
end
