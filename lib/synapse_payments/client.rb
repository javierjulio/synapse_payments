require 'http'

module SynapsePayments
  class Client

    API_TEST = 'https://sandbox.synapsepay.com/api/3'
    API_LIVE = 'https://synapsepay.com/api/3'

    attr_accessor :client_id, :client_secret, :sandbox_mode, :timeout_options
    attr_reader :api_base, :users, :subscriptions

    # Initializes a new Client object
    #
    # @param options [Hash]
    # @return [SynapsePayments::Client]
    def initialize(options={})
      @sandbox_mode = true
      @timeout_options = { write: 2, connect: 5, read: 10 }

      options.each do |key, value|
        instance_variable_set("@#{key}", value)
      end

      yield(self) if block_given?

      @api_base = @sandbox_mode ? API_TEST : API_LIVE

      @users = Users.new(self)
      @subscriptions = Subscriptions.new(self)
    end

    # @return [Hash]
    def credentials
      {
        client_id: client_id,
        client_secret: client_secret
      }
    end

    # @return [Boolean]
    def credentials?
      credentials.values.all?
    end

    # @return [Array]
    def institutions
      institutions = HTTP.get('https://synapsepay.com/api/v3/institutions/show').parse
      symbolize_keys!(institutions)
      institutions[:banks]
    end

    def get(path:, oauth_key: nil, fingerprint: nil)
      Request.new(client: self, method: :get, path: path, oauth_key: oauth_key, fingerprint: fingerprint).perform
    end

    def post(path:, json:, oauth_key: nil, fingerprint: nil, idempotency_key: nil)
      Request.new(client: self, method: :post, path: path, oauth_key: oauth_key, fingerprint: fingerprint, json: json, idempotency_key: idempotency_key).perform
    end

    def patch(path:, json:, oauth_key: nil, fingerprint: nil)
      Request.new(client: self, method: :patch, path: path, oauth_key: oauth_key, fingerprint: fingerprint, json: json).perform
    end

    def delete(path:, oauth_key: nil, fingerprint: nil)
      Request.new(client: self, method: :delete, path: path, oauth_key: oauth_key, fingerprint: fingerprint).perform
    end

    def symbolize_keys!(object)
      if object.is_a?(Array)
        object.each_with_index do |val, index|
          object[index] = symbolize_keys!(val)
        end
      elsif object.is_a?(Hash)
        object.keys.each do |key|
          object[key.to_sym] = symbolize_keys!(object.delete(key))
        end
      end
      object
    end

  end
end
