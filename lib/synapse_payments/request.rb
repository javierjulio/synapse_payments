module SynapsePayments
  class Request

    HEADERS = {
      'User-Agent'      => "SynapsePaymentsRubyGem/#{SynapsePayments::VERSION}",
      'X-Ruby-Version'  => RUBY_VERSION,
      'X-Ruby-Platform' => RUBY_PLATFORM
    }

    def initialize(client:, method:, path:, oauth_key: nil, fingerprint: nil, json: nil, idempotency_key: nil)
      @client = client
      @method = method
      @path = path
      @oauth_key = oauth_key
      @fingerprint = fingerprint
      @json = json
      @idempotency_key = idempotency_key
    end

    def perform
      options_key = @method == :get ? :params : :json
      response = http_client.public_send(@method, "#{@client.api_base}#{@path}", options_key => @json)
      response_body = @client.symbolize_keys!(response.parse)
      fail_or_return_response_body(response.code, response_body)
    end

    private

    def http_client
      headers = HEADERS.merge({
        'X-SP-GATEWAY' => "#{@client.client_id}|#{@client.client_secret}",
        'X-SP-USER' => "#{@oauth_key}|#{@fingerprint}",
        'X-SP-USER-IP' => ''
      })

      if !@idempotency_key.nil?
        headers = headers.merge({ 'X-SP-IDEMPOTENCY-KEY' => @idempotency_key })
      end

      HTTP.headers(headers).accept(:json).timeout(@client.timeout_options)
    end

    def fail_or_return_response_body(code, body)
      if code < 200 || code >= 206
        error = SynapsePayments::Error.error_from_response(body, code)
        fail(error)
      end
      body
    end

  end
end
