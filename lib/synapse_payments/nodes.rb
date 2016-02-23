module SynapsePayments
  class Nodes

    def initialize(client, user_id, oauth_key, fingerprint)
      @client = client
      @user_id = user_id
      @oauth_key = oauth_key
      @fingerprint = fingerprint
    end

    def all
      @client.get(path: "/users/#{@user_id}/nodes", oauth_key: @oauth_key, fingerprint: @fingerprint)
    end

    def find(id)
      @client.get(path: "/users/#{@user_id}/nodes/#{id}", oauth_key: @oauth_key, fingerprint: @fingerprint)
    end

    def create(data)
      @client.post(path: "/users/#{@user_id}/nodes", oauth_key: @oauth_key, fingerprint: @fingerprint, json: data)
    end

    def delete(id)
      @client.delete(path: "/users/#{@user_id}/nodes/#{id}", oauth_key: @oauth_key, fingerprint: @fingerprint)
    end

    def update(id, data)
      @client.patch(path: "/users/#{@user_id}/nodes/#{id}", oauth_key: @oauth_key, fingerprint: @fingerprint, json: data)
    end

  end

end
