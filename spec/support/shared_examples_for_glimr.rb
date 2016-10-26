RSpec.shared_examples 'glimr availability request' do |glimr_response|
  before do
    Excon.stub(
      {
        host: 'glimr-api.taxtribunals.dsd.io',
        path: '/Live_API/api/tdsapi/glimravailable'
      },
      status: 200, body: glimr_response.to_json
    )
  end
end

RSpec.shared_examples 'glimr availability request returns a 500' do
  before do
    Excon.stub(
      {
        host: 'glimr-api.taxtribunals.dsd.io',
        path: '/Live_API/api/tdsapi/glimravailable'
      },
      status: 500
    )
  end
end

RSpec.shared_examples 'service is not available' do
  scenario do
    visit '/'
    expect(page).not_to have_text('Start now')
    expect(page).to have_text('The service is currently unavailable')
  end
end

RSpec.shared_examples 'generic glimr response' do |case_number, _confirmation_code, status, glimr_response|
  before do
    Excon.stub(
      {
        host: 'glimr-api.taxtribunals.dsd.io',
        body: /caseNumber=#{CGI.escape(case_number)}/,
        path: '/Live_API/api/tdsapi/requestpayablecasefees'
      },
      status: status, body: glimr_response.to_json
    )
  end
end

RSpec.shared_examples 'case not found' do
  before do
    Excon.stub(
      {
        host: 'glimr-api.taxtribunals.dsd.io',
        path: '/Live_API/api/tdsapi/requestpayablecasefees'
      },
      status: 404
    )
  end
end

RSpec.shared_examples 'no new fees are due' do |case_number, _confirmation_code|
  let(:response_body) {
    {
      'jurisdictionId' => 8,
      'tribunalCaseId' => 60_029,
      'caseTitle' => 'You vs HM Revenue & Customs',
      'feeLiabilities' => []
    }
  }

  before do
    Excon.stub(
      {
        host: 'glimr-api.taxtribunals.dsd.io',
        body: /caseNumber=#{CGI.escape(case_number)}/,
        path: '/Live_API/api/tdsapi/requestpayablecasefees'
      },
      status: 200, body: response_body.to_json
    )
  end
end

RSpec.shared_examples 'a case fee of £20 is due' do |case_number, _confirmation_code|
  let(:response_body) {
    {
      'jurisdictionId' => 8,
      'tribunalCaseId' => 60_029,
      'caseTitle' => 'You vs HM Revenue & Customs',
      'feeLiabilities' =>
      [{ 'feeLiabilityId' => '7',
         'onlineFeeTypeDescription' => 'Lodgement Fee',
         'payableWithUnclearedInPence' => '2000' }]
    }.to_json
  }

  before do
    Excon.stub(
      {
        method: :post,
        host: 'glimr-api.taxtribunals.dsd.io',
        body: /caseNumber=#{CGI.escape(case_number)}&jurisdictionId=8/,
        path: '/Live_API/api/tdsapi/requestpayablecasefees'
      },
      status: 200, body: response_body
    )
  end
end

RSpec.shared_examples 'no fees then a £20 fee' do |case_number, _confirmation_code|
  let(:no_fees) {
    {
      'jurisdictionId' => 8,
      'tribunalCaseId' => 60_029,
      'caseTitle' => 'You vs HM Revenue & Customs',
      'feeLiabilities' => []
    }
  }

  let(:twenty_pound_fee) {
    {
      'jurisdictionId' => 8,
      'tribunalCaseId' => 60_029,
      'caseTitle' => 'You vs HM Revenue & Customs',
      'feeLiabilities' =>
      [{ 'feeLiabilityId' => 7,
         'onlineFeeTypeDescription' => 'Lodgement Fee',
         'payableWithUnclearedInPence' => 2000 }]
    }
  }

  before do
    Excon.stub(
      {
        method: :post,
        host: 'glimr-api.taxtribunals.dsd.io',
        body: /caseNumber=#{CGI.escape(case_number)}/,
        path: '/Live_API/api/tdsapi/requestpayablecasefees'
      },
      status: 200, body: no_fees.to_json
    )

    Excon.stub(
      {
        method: :post,
        host: 'glimr-api.taxtribunals.dsd.io',
        body: /caseNumber=#{CGI.escape(case_number)}/,
        path: '/Live_API/api/tdsapi/requestpayablecasefees'
      },
      status: 200, body: twenty_pound_fee.to_json
    )
  end
end

RSpec.shared_examples 'report payment taken to glimr' do |req_body|
  let(:paymenttaken_response) {
    {
      feeLiabilityId: 1234,
      feeTransactionId: 1234,
      paidAmountInPence: 9999
    }
  }

  before do
    Excon.stub(
      {
        method: :post,
        host: 'glimr-api.taxtribunals.dsd.io',
        body: req_body,
        path: '/Live_API/api/tdsapi/paymenttaken'
      },
      status: 200, body: paymenttaken_response.to_json
    )
  end
end

RSpec.shared_examples 'glimr fee_paid returns a 500' do
  before do
    Excon.stub(
      {
        method: :post,
        host: 'glimr-api.taxtribunals.dsd.io',
        path: '/Live_API/api/tdsapi/paymenttaken'
      },
      status: 500
    )
  end
end

RSpec.shared_examples 'glimr times out' do
  let(:glimr_check) {
    class_double(Excon, 'glimr availability')
  requestpayablecasefees}

  before do
    expect(glimr_check).
      to receive(:post).
      with(path: '/Live_API/api/tdsapi/glimravailable', body: '').
      and_raise(Excon::Errors::Timeout)

    expect(Excon).to receive(:new).
      with(Rails.configuration.glimr_api_url, anything).
      and_return(glimr_check)
  end
end

RSpec.shared_examples 'glimr has a socket error' do
  let(:glimr_check) {
    class_double(Excon, 'glimr availability')
  }

  before do
    expect(glimr_check).
      to receive(:post).
      with(body: '').
      and_raise(Excon::Errors::SocketError)

    expect(Excon).to receive(:new).
      with('https://glimr-api.taxtribunals.dsd.io/Live_API/api/tdsapi/glimravailable', anything).
      and_return(glimr_check)
  end
end

RSpec.shared_examples 'register new case with glimr' do |req_body|
  let(:registernewcase_response) {
    {
      jurisdictionId: 8,
      tribunalCaseId: '12345678',
      tribunalCaseNumber: "TC/2016/00006",
      caseTitle: "John James vs HMRC"
    }
  }

  before do
    Excon.stub(
      {
        method: :post,
        host: 'glimr-api.taxtribunals.dsd.io',
        path: '/Live_API/api/tdsapi/registernewcase'
      },
      status: 200, body: registernewcase_response.to_json
    )
  end
end

