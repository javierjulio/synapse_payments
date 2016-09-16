module SynapsePayments
  class UserClient

    def initialize(client, user_id, fingerprint, response)
      @client = client
      @user_id = user_id
      @fingerprint = fingerprint
      @response = response
      @oauth_key = response[:oauth_key]

      response.each do |key, value|
        (class << self; self; end).class_eval do
          define_method key do |*args|
            response[key]
          end
        end
      end

      @nodes = Nodes.new(@client, @user_id, @oauth_key, @fingerprint)
    end

    def user
      @client.get(path: "/users/#{@user_id}", oauth_key: @oauth_key)
    end

    def update(data)
      raise ArgumentError, 'Argument is not a hash' unless data.is_a? Hash

      if data[:doc].nil?
        data = { refresh_token: self.refresh_token, update: data }
      end

      @client.patch(path: "/users/#{@user_id}", oauth_key: @oauth_key, fingerprint: @fingerprint, json: data)
    end

    # Adds multiple virtual/physical/social documents
    #
    # @param email [String]
    # @param phone_Number [String]
    # @param ip [String]
    # @param name [String] "First Last"
    # @param aka [String] can be same as name or DBA if business
    # @param entity_type [String] gender if personal or corp type if business
    # @param entity_scope [String] profession or industry
    # @param day [String]
    # @param month [String]
    # @param year [String]
    # @param address_street [String]
    # @param address_subdivision [String] (state or equivalent)
    # @param address_postal_code [String]
    # @param country_code [String] The country code in ISO format e.g. US
    # @param (optional) virtual_docs [Array of Hashes]
      # [{document_value: String, document_type: String}]
    # @param (optional) physical_docs [Array of Hashes]
      # [{document_value: String, document_type: String}]
    # @param (optional) social_docs [Array of Hashes]
      # [{document_value: String, document_type: String}]
    # Acceptable document types: https://docs.synapsepay.com/docs/user-resources#customer-identification-program-cip--know-your-cus
    # @return [Hash]
    def add_documents(email:, phone_number:, ip:, name:, aka:, entity_type:, entity_scope:, day:, month:, year:, address_street:, address_city:, address_subdivision:, address_postal_code:, address_country_code:, **args)
      data = {
        documents: [{
          email: email,
          phone_number: phone_number,
          ip: ip,
          name: name,
          alias: aka,
          entity_type: entity_type,
          entity_scope: entity_scope,
          day: day,
          month: month,
          year: year,
          address_street: address_street,
          address_city: address_city,
          address_subdivision: address_subdivision,
          address_postal_code: address_postal_code,
          address_country_code: address_country_code
        }]
      }
      document_body = data[:documents][0]
      document_body[:virtual_docs] = args[:virtual_docs] if args[:virtual_docs]
      document_body[:physical_docs] = args[:physical_docs] if args[:physical_docs]
      document_body[:social_docs] = args[:social_docs] if args[:physical_docs]

      @client.patch(path: "/users/#{@user_id}", oauth_key: @oauth_key, fingerprint: @fingerprint, json: data)
    end

    # @param answers [Hash] in this format:
      # {documents_id:, virtual_doc_id:, answers: [{question_id:, answer_id:}, {question_id:, answer_id:}]
    def update_documents_with_kba_answers(answers)
      raise ArgumentError, 'Argument is not a hash' unless answers.is_a? Hash

      data = {
        documents: [
          id: answers[:documents_id],
          virtual_docs: [{
            id: answers[:virtual_doc_id],
            meta: {
              question_set: {
                answers: answers[:answers]
              }
            }
          }]
        ]
      }

      @client.patch(path: "/users/#{@user_id}", oauth_key: @oauth_key, fingerprint: @fingerprint, json: data)
    end

    # Adds a bank account by creating a node of node type ACH-US using acct/routing number
    #
    # @param name [String] the name of the account holder
    # @param account_number [String]
    # @param routing_number [String]
    # @param category [String] the account category, `personal` or `business`
    # @param type [String] the account type, `checking` or `savings`
    # @return [Hash]
    def add_bank_account(name:, account_number:, routing_number:, category:, type:, **args)
      data = {
        type: 'ACH-US',
        info: {
          nickname: args[:nickname] || name,
          name_on_account: name,
          account_num: account_number,
          routing_num: routing_number,
          type: category,
          class: type
        },
        extra: {
          supp_id: args[:supp_id]
        }
      }
      nodes.create(data)
    end

    def bank_login(bank_name:, username:, password:)
      data = {
        type: 'ACH-US',
        info: {
          bank_id: username,
          bank_pw: password,
          bank_name: bank_name
        }
      }

      nodes.create(data)
    end

    def verify_mfa(access_token:, answer:)
      data = {
        access_token: access_token,
        mfa_answer: answer
      }

      nodes.create(data)
    end

    def send_money(from:, to:, to_node_type:, amount:, currency:, ip_address:, **args)
      nodes(from).transactions.create(node_id: to, node_type: to_node_type, amount: amount, currency: currency, ip_address: ip_address, **args)
    end

    def nodes(id=nil)
      if id.nil?
        @nodes
      else
        Node.new(@client, @user_id, id, @oauth_key, @fingerprint)
      end
    end
    
    # DEPRECATED: use #add_documents
    # Adds a virtual document for KYC
    #
    # @param birthdate [Date]
    # @param first_name [String]
    # @param last_name [String]
    # @param street [String]
    # @param postal_code [String]
    # @param country_code [String] The country code in ISO format e.g. US
    # @param document_type [String] Acceptable document types: SSN, PASSPORT, DRIVERS_LICENSE, PERSONAL_IDENTIFICATION, NONE
    # @param document_value [String]
    # @return [Hash]
    def add_document(birthdate:, first_name:, last_name:, street:, postal_code:, country_code:, document_type:, document_value:)
      # advise using new API call format
      warn Kernel.caller.first + ' deprecation warning: UserClient#add_document is deprecated in favor of #add_documents'

      data = {
        doc: {
          birth_day: birthdate.day,
          birth_month: birthdate.month,
          birth_year: birthdate.year,
          name_first: first_name,
          name_last: last_name,
          address_street1: street,
          address_postal_code: postal_code,
          address_country_code: country_code,
          document_type: document_type,
          document_value: document_value
        }
      }

      @client.patch(path: "/users/#{@user_id}", oauth_key: @oauth_key, fingerprint: @fingerprint, json: data)
    end

    # DEPRECATED: use #update_documents_with_kba_answers
    def answer_kba(question_set_id:, answers:)
      # advise using new API call format
      warn Kernel.caller.first + ' deprecation warning: UserClient#answer_kba is deprecated in favor of #update_documents_with_kba_answers({documents_id:, virtual_doc_id:, answers: [{question_id:, answer_id},{...}])'

      data = {
        doc: {
          question_set_id: question_set_id,
          answers: answers
        }
      }

      @client.patch(path: "/users/#{@user_id}", oauth_key: @oauth_key, fingerprint: @fingerprint, json: data)
    end

  end
end
