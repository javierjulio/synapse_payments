module SynapsePayments
  class Transactions

    def initialize(client, user_id, node_id, oauth_key, fingerprint)
      @client = client
      @user_id = user_id
      @node_id = node_id
      @oauth_key = oauth_key
      @fingerprint = fingerprint
    end

    def all
      @client.get(path: "/users/#{@user_id}/nodes/#{@node_id}/trans", oauth_key: @oauth_key, fingerprint: @fingerprint)
    end

    def create(node_id:, node_type:, amount:, currency:, ip_address:, idempotency_key: nil, **args)
      data = {
        to: {
          type: node_type,
          id: node_id
        },
        amount: {
          amount: amount,
          currency: currency
        },
        extra: (args[:extra] || {}).merge({ ip: ip_address })
      }

      data = data.merge(fees: args[:fees]) if args[:fees]

      @client.post(path: "/users/#{@user_id}/nodes/#{@node_id}/trans", oauth_key: @oauth_key, fingerprint: @fingerprint, json: data, idempotency_key: idempotency_key)
    end

    def delete(id)
      @client.delete(path: "/users/#{@user_id}/nodes/#{@node_id}/trans/#{id}", oauth_key: @oauth_key, fingerprint: @fingerprint)
    end

    def find(id)
      @client.get(path: "/users/#{@user_id}/nodes/#{@node_id}/trans/#{id}", oauth_key: @oauth_key, fingerprint: @fingerprint)
    end

    def update(id, data)
      @client.patch(path: "/users/#{@user_id}/nodes/#{@node_id}/trans/#{id}", oauth_key: @oauth_key, fingerprint: @fingerprint, json: data)
    end

  end

end
