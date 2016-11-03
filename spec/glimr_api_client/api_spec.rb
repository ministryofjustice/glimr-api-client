require 'rails_helper'

RSpec.describe GlimrApiClient::Api, '#post' do
  let(:docpath) { '/Live_API/api/tdsapi' }
  let(:api_endpoint) { 'endpoint' }
  let(:path) { [docpath, api_endpoint].join('/') }

  # Required for run/build ordering in mutation tests.
  let(:object) do
    Class.new do
      include GlimrApiClient::Api

      def initialize(call = nil)
        @call = call
      end

      def call
        "called#{@call}"
      end

      def request_body
        { parameter: 'parameter' }
      end
    end.new
  end

  before do
    object.instance_eval do
      def endpoint
        '/endpoint'
      end
    end
  end

  it 'exposes an excon client' do
    Excon.stub(
      {
        method: :post,
        body: { parameter: "parameter" }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        },
      path: path,
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
          path: path
        },
        status: 404
      )
      expect { object.post }.to raise_error(GlimrApiClient::CaseNotFound, '404')
    end

    it 'raises an exception when it receives a 500' do
      Excon.stub(
        {
          method: :post,
          path: path
        },
        status: 500
      )
      expect { object.post }.to raise_error(GlimrApiClient::Unavailable, '500')
    end

    it 'raises an exception when it receives a 400' do
      Excon.stub(
        {
          method: :post,
          path: path
        },
        status: 400
      )
      expect { object.post }.to raise_error(GlimrApiClient::Unavailable, '400')
    end

    it 'does not raise exceptions for 3xx range codes' do
      Excon.stub(
        {
          method: :post,
          path: path
        },
        status: 399
      )
      expect { object.post }.not_to raise_error
    end

    it 'does not raise exceptions for out-of-range codes' do
      Excon.stub(
        {
          method: :post,
          path: path
        },
        status: 600
      )
      expect { object.post }.not_to raise_error
    end

    it 'raises an exception when it receives a 599' do
      Excon.stub(
        {
          method: :post,
          path: path
        },
        status: 599
      )
      expect { object.post }.to raise_error(GlimrApiClient::Unavailable, '599')
    end

    context '/paymenttaken' do
      let(:api_endpoint) { 'paymenttaken' }

      before do
        object.instance_eval do
          def endpoint
            '/paymenttaken'
          end
        end
      end

      it 'does not raise exceptions for 3xx range codes' do
        Excon.stub(
          {
            method: :post,
            path: path
          },
          status: 399
        )
        expect { object.post }.not_to raise_error
      end

      it 'does not raise exceptions for out-of-range codes' do
        Excon.stub(
          {
            method: :post,
            path: path
          },
          status: 600
        )
        expect { object.post }.not_to raise_error
      end

      it 're-raises a 404 with the correct error' do
        Excon.stub(
          {
            method: :post,
            path: path
          },
          status: 404
        )
        expect { object.post }.to raise_error(GlimrApiClient::PaymentNotificationFailure, '404')
      end

      it 're-raises a 500 with the correct error' do
        Excon.stub(
          {
            method: :post,
            path: path
          },
          status: 500
        )
        expect { object.post }.to raise_error(GlimrApiClient::PaymentNotificationFailure, '500')
      end

      context 'when the client dies' do
        let(:excon) { class_double(Excon) }

        before do
          expect(excon).to receive(:post).and_raise(Excon::Error, 'it died')
        end

        it 'raises a payment notification exception' do
          expect(object).to receive(:client).and_return(excon)
          expect { object.post }.to raise_error(GlimrApiClient::PaymentNotificationFailure, 'it died')
        end
      end

    end

    context '/registernewcase' do
      let(:api_endpoint) { 'registernewcase' }

      before do
        object.instance_eval do
          def endpoint
            '/registernewcase'
          end
        end
      end

      it 'does not raise exceptions for 3xx range codes' do
        Excon.stub(
          {
            method: :post,
            path: path
          },
          status: 399
        )
        expect { object.post }.not_to raise_error
      end

      it 'does not raise exceptions for out-of-range codes' do
        Excon.stub(
          {
            method: :post,
            path: path
          },
          status: 600
        )
        expect { object.post }.not_to raise_error
      end

      it 're-raises a 500 with the correct error' do
        Excon.stub(
          {
            method: :post,
            path: path
          },
          status: 500
        )
        expect { object.post }.to raise_error(GlimrApiClient::RegisterNewCaseFailure, '500')
      end

      context 'when the client dies' do
        let(:excon) { class_double(Excon) }

        before do
          expect(excon).to receive(:post).and_raise(Excon::Error, 'it died')
        end

        it 'raises a register new case exception' do
          expect(object).to receive(:client).and_return(excon)
          expect { object.post }.to raise_error(GlimrApiClient::RegisterNewCaseFailure, 'it died')
        end
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
  end
end
