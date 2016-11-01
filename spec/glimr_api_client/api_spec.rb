require 'rails_helper'
require 'support/shared_examples_for_api_calls'

RSpec.describe GlimrApiClient::Api, '#post' do
  include_examples 'anonymous object'

  it 'exposes an excon client' do
    Excon.stub(
      {
        method: :post,
        body: { parameter: "parameter" }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        },
      path: '/Live_API/api/tdsapi/endpoint',
      persistent: true
      },
      status: 200, body: { response: 'response' }.to_json
    )
    object.tap do |o|
      expect { o.post }.not_to raise_error
      expect(o.response_body).to eq({ response: 'response' })
    end
  end

  context 'common errors' do
    it 'raises case not found on 404' do
      Excon.stub(
        {
          method: :post,
          path: '/Live_API/api/tdsapi/endpoint'
        },
        status: 404
      )
      expect { object.post }.to raise_error(GlimrApiClient::CaseNotFound, '404')
    end

    it 'raises an exception when it receives a 500' do
      Excon.stub(
        {
          method: :post,
          path: '/Live_API/api/tdsapi/endpoint'
        },
        status: 500
      )
      expect { object.post }.to raise_error(GlimrApiClient::Unavailable, '500')
    end

    it 'raises an exception when it receives a 400' do
      Excon.stub(
        {
          method: :post,
          path: '/Live_API/api/tdsapi/endpoint'
        },
        status: 400
      )
      expect { object.post }.to raise_error(GlimrApiClient::Unavailable, '400')
    end

    it 'does not raise exceptions for 3xx range codes' do
      Excon.stub(
        {
          method: :post,
          path: '/Live_API/api/tdsapi/endpoint'
        },
        status: 399
      )
      expect { object.post }.not_to raise_error
    end

    it 'does not raise exceptions for out-of-range codes' do
      Excon.stub(
        {
          method: :post,
          path: '/Live_API/api/tdsapi/endpoint'
        },
        status: 600
      )
      expect { object.post }.not_to raise_error
    end

    it 'raises an exception when it receives a 599' do
      Excon.stub(
        {
          method: :post,
          path: '/Live_API/api/tdsapi/endpoint'
        },
        status: 599
      )
      expect { object.post }.to raise_error(GlimrApiClient::Unavailable, '599')
    end

    context '/paymenttaken' do

      it 'does not raise exceptions for 3xx range codes' do
        Excon.stub(
          {
            method: :post,
            path: '/Live_API/api/tdsapi/paymenttaken'
          },
          status: 399
        )
        expect { paymenttaken_object.post }.not_to raise_error
      end

      it 'does not raise exceptions for out-of-range codes' do
        Excon.stub(
          {
            method: :post,
            path: '/Live_API/api/tdsapi/paymenttaken'
          },
          status: 600
        )
        expect { paymenttaken_object.post }.not_to raise_error
      end

      it 're-raises a 404 with the correct error' do
        Excon.stub(
          {
            method: :post,
            path: '/Live_API/api/tdsapi/paymenttaken'
          },
          status: 404
        )
        expect { paymenttaken_object.post }.to raise_error(GlimrApiClient::PaymentNotificationFailure, '404')
      end

      it 're-raises a 500 with the correct error' do
        Excon.stub(
          {
            method: :post,
            path: '/Live_API/api/tdsapi/paymenttaken'
          },
          status: 500
        )
        expect { paymenttaken_object.post }.to raise_error(GlimrApiClient::PaymentNotificationFailure, '500')
      end
    end

    context '/registernewcase' do

      it 'does not raise exceptions for 3xx range codes' do
        Excon.stub(
          {
            method: :post,
            path: '/Live_API/api/tdsapi/registernewcase'
          },
          status: 399
        )
        expect { registernewcase_object.post }.not_to raise_error
      end

      it 'does not raise exceptions for out-of-range codes' do
        Excon.stub(
          {
            method: :post,
            path: '/Live_API/api/tdsapi/registernewcase'
          },
          status: 600
        )
        expect { registernewcase_object.post }.not_to raise_error
      end

      it 're-raises a 500 with the correct error' do
        Excon.stub(
          {
            method: :post,
            path: '/Live_API/api/tdsapi/registernewcase'
          },
          status: 500
        )
        expect { registernewcase_object.post }.to raise_error(GlimrApiClient::RegisterNewCaseFailure, '500')
      end
    end
  end

  context 'the client dies without returning' do
    let(:excon) {
      class_double(Excon)
    }

    before do
      expect(excon).to receive(:post).and_raise(Excon::Error, 'it died')
    end

    it 'raises an exception if the client dies' do
      expect(object).to receive(:client).and_return(excon)
      expect { object.post }.to raise_error(GlimrApiClient::Unavailable, 'it died')
    end

    it 'raises a payment notification exception if the client dies' do
      expect(paymenttaken_object).to receive(:client).and_return(excon)
      expect { paymenttaken_object.post }.to raise_error(GlimrApiClient::PaymentNotificationFailure, 'it died')
    end

    it 'raises a register new case exception if the client dies' do
      expect(registernewcase_object).to receive(:client).and_return(excon)
      expect { registernewcase_object.post }.to raise_error(GlimrApiClient::RegisterNewCaseFailure, 'it died')
    end
  end
end
