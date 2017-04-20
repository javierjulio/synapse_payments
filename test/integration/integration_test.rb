require 'test_helper'

class IntegrationTest < Minitest::Test

  def setup
    # To setup a test user for tests create one in the console with:
    # result = client.users.create(name: 'John Doe', email: 'john@test.com', phone: '123-456-8790', fingerprint: fingerprint)
    # And then store the of result[:_id] in the .env file for the USER_ID env var.

    skip if ENV['USER_ID'].nil? || ENV['USER_ID'].empty?

    disable_vcr!

    @fingerprint = ENV.fetch('SYNAPSE_PAYMENTS_FINGERPRINT')
    @user_id = ENV['USER_ID']
    @user = authenticated_client.users.find(@user_id)
    @user_client = authenticated_client.users.authenticate_as(id: @user_id, refresh_token: @user[:refresh_token], fingerprint: @fingerprint)
  end

  def teardown
    @user_id = nil
    @user = nil
    @user_client = nil
    @fingerprint = nil
  end

  def test_create_user_with_fingerprint_and_data
    user = authenticated_client.users.create(name: 'John Doe', email: 'john@test.com', phone: '123-456-8790', fingerprint: @fingerprint)
    user_client = authenticated_client.users.authenticate_as(id: user[:_id], refresh_token: user[:refresh_token], fingerprint: @fingerprint)

    refute_nil user_client.expires_at
    refute_nil user_client.expires_in
    refute_nil user_client.refresh_expires_in
    refute_nil user_client.refresh_token

    response = user_client.nodes.all
    assert response[:success]

    user = user_client.update(legal_name: 'Jonathan Doe')
    refute_predicate user[:_id], :empty?
    assert_equal ['John Doe', 'Jonathan Doe'], user[:legal_names]

    bank = user_client.add_bank_account(
      name: 'Jonathan Doe',
      account_number: '123456786',
      routing_number: '051000017',
      category: 'PERSONAL',
      type: 'CHECKING'
    )
    assert bank[:success]

    node_id = bank[:nodes].first[:_id]

    response = user_client.nodes(node_id).transactions.all
    assert response[:success]

    data = {
      type: 'SYNAPSE-US',
      info: {
        nickname: 'My First Integration Test Synapse Wallet'
      },
      extra: {
        supp_id: 123456
      }
    }

    node = user_client.nodes.create(data)

    response = user_client.nodes.all
    assert response[:success]
    assert_equal 2, response[:nodes].size

    transaction = user_client.send_money(
      from: bank[:nodes].first[:_id],
      to: node[:nodes].first[:_id],
      to_node_type: 'SYNAPSE-US',
      amount: 24.00,
      currency: 'USD',
      ip_address: '192.168.0.1',
      extra: {
        supp_id: '4321'
      },
      fees: [
        {
          fee: 0.05,
          note: 'Business Fee',
          to: {
            id: '559339aa86c273605ccd35df'
          }
        }
      ]
    )
  end

  def test_authenticate_as
    user_client = authenticated_client.users.authenticate_as(id: @user_id, refresh_token: @user[:refresh_token], fingerprint: @fingerprint)

    refute_predicate user_client.refresh_token, :empty?
  end

  def test_add_document_successful
    user = @user_client.add_document(
      birthdate: Date.parse('1970/3/14'),
      first_name: 'John',
      last_name: 'Doe',
      street: '1 Infinite Loop',
      postal_code: '95014',
      country_code: 'US',
      document_type: 'SSN',
      document_value: '2222'
    )

    refute_predicate user[:_id], :empty?
  end

  def test_add_document_with_kba_answer
    response = @user_client.add_document(
      birthdate: Date.parse('1970/3/14'),
      first_name: 'John',
      last_name: 'Doe',
      street: '1 Infinite Loop',
      postal_code: '95014',
      country_code: 'US',
      document_type: 'SSN',
      document_value: '3333'
    )

    user = @user_client.answer_kba(
      question_set_id: response[:question_set][:id],
      answers: [
  			{ question_id: 1, answer_id: 1 },
  			{ question_id: 2, answer_id: 1 },
  			{ question_id: 3, answer_id: 1 },
  			{ question_id: 4, answer_id: 1 },
  			{ question_id: 5, answer_id: 1 }
      ]
    )
  end

  def test_add_document_failure_with_attached_photo_id
    begin
      response = @user_client.add_document(
        birthdate: Date.parse('1970/3/14'),
        first_name: 'John',
        last_name: 'Doe',
        street: '1 Infinite Loop',
        postal_code: '95014',
        country_code: 'US',
        document_type: 'SSN',
        document_value: '1111'
      )
    rescue SynapsePayments::Error::Conflict => error
      # no identity found, validation not possible, submit photo ID
    end

    file_contents = File.read(fixture_path('image.png'))
    payload_data = "data:image/png;base64,#{Base64.encode64(file_contents).gsub(/\n/, '')}"

    user = @user_client.update(doc: { attachment: payload_data })

    refute_predicate user[:_id], :empty?
  end

  def test_add_documents_successful
    virtual_docs = [{
        'document_value': '111-111-2222',
        'document_type': 'SSN'
    }]
    physical_docs = [{
        'document_value': 'data:text/csv;base64,SUQs==',
        'document_type': 'GOVT_ID'
      },
      {
        'document_value': 'data:text/csv;base64,SUQs==',
        'document_type': 'SELFIE'
    }]
    social_docs = [{
      'document_value': 'https://www.facebook.com/sankaet',
      'document_type': 'FACEBOOK'
    }]

    user = @user_client.add_documents(
      email: 'test@test.com',
      phone_number: '5555555555',
      ip: '127.0.0.1',
      name: 'John Doe',
      aka: 'Johnie Doe',
      entity_type: 'M',
      entity_scope: 'Arts & Entertainment',
      day: 14,
      month: 3,
      year: 1970,
      address_street: '1 Infinite Loop',
      address_city: 'Cupertino',
      address_subdivision: 'CA',
      address_postal_code: '95014',
      address_country_code: 'US',
      virtual_docs: virtual_docs,
      physical_docs: physical_docs,
      social_docs: social_docs
    )

    refute_predicate user[:_id], :empty?
  end

  def test_add_documents_with_kba_answers
      virtual_docs = [{
          'document_value': '111-111-3333',
          'document_type': 'SSN'
      }]

      response = @user_client.add_documents(
        email: 'test@test.com',
        phone_number: '5555555555',
        ip: '127.0.0.1',
        name: 'John Doe',
        aka: 'Johnie Doe',
        entity_type: 'M',
        entity_scope: 'Arts & Entertainment',
        day: 14,
        month: 3,
        year: 1970,
        address_street: '1 Infinite Loop',
        address_city: 'Cupertino',
        address_subdivision: 'CA',
        address_postal_code: '95014',
        address_country_code: 'US',
        virtual_docs: virtual_docs
      )

      # this could be improved. selects the most recently submitted set of documents,
      # under assumption that those contain the KBA problem.
      documents = response[:documents][-1]
      kba_doc = documents[:virtual_docs].find {|doc| doc[:document_type] == 'SSN'}
      documents_id = documents[:id]
      virtual_doc_id = kba_doc[:id]

      data = {
        documents_id: documents_id,
        virtual_doc_id: virtual_doc_id, 
        answers: [
          { question_id: 1, answer_id: 1 },
          { question_id: 2, answer_id: 1 },
          { question_id: 3, answer_id: 1 },
          { question_id: 4, answer_id: 1 },
          { question_id: 5, answer_id: 1 }
        ]}

      user = @user_client.update_documents_with_kba_answers(data)
  end

  def test_add_bank_account_with_verified_micro_deposit
    account_number = Time.now.to_i

    response = @user_client.add_bank_account(
      name: 'John Doe',
      account_number: account_number,
      routing_number: '051000017',
      category: 'PERSONAL',
      type: 'CHECKING'
    )

    node = response[:nodes][0]

    assert response[:success]
    assert_equal 1, response[:nodes].size
    refute_predicate node[:_id], :empty?
    assert_equal 'John Doe', node[:info][:name_on_account]
    assert_equal 'PERSONAL', node[:info][:type]
    assert_equal 'CHECKING', node[:info][:class]
    assert_equal account_number.to_s.chars.last(4).join, node[:info][:account_num]
    assert_equal '0017', node[:info][:routing_num]
    assert_equal 'ACH-US', node[:type]
    assert_equal 'CREDIT', node[:allowed]

    response = @user_client.nodes.update(node[:_id], micro: [0.1, 0.1])

    assert_equal 'CREDIT-AND-DEBIT', response[:allowed]

    @user_client.nodes.delete(node[:_id])
  end

  def test_add_bank_account_with_incorrect_micro_deposit_and_locked_node
    account_number = Time.now.to_i

    response = @user_client.add_bank_account(
      name: 'John Doe',
      account_number: account_number,
      routing_number: '051000017',
      category: 'PERSONAL',
      type: 'CHECKING'
    )

    node = response[:nodes][0]

    assert response[:success]
    assert_equal 1, response[:nodes].size
    refute_predicate node[:_id], :empty?
    assert_equal 'John Doe', node[:info][:name_on_account]
    assert_equal 'PERSONAL', node[:info][:type]
    assert_equal 'CHECKING', node[:info][:class]
    assert_equal account_number.to_s.chars.last(4).join, node[:info][:account_num]
    assert_equal '0017', node[:info][:routing_num]
    assert_equal 'ACH-US', node[:type]
    assert_equal 'CREDIT', node[:allowed]

    error = assert_raises(SynapsePayments::Error::Conflict) {
      @user_client.nodes.update(node[:_id], micro: [0.1, 0.3])
    }
    assert_kind_of SynapsePayments::Error::ClientError, error
    assert error.message =~ /incorrect/i
    # If all tries used up then node permission is LOCKED.
    assert error.message =~ /\d{1,}\s{1,}tries\s{1,}left/i

    error = assert_raises(SynapsePayments::Error::Conflict) {
      @user_client.nodes.update(node[:_id], micro: [0.1, 0.3])
    }
    assert error.message =~ /3 tries left/i

    error = assert_raises(SynapsePayments::Error::Conflict) {
      @user_client.nodes.update(node[:_id], micro: [0.1, 0.3])
    }
    assert error.message =~ /2 tries left/i

    error = assert_raises(SynapsePayments::Error::Conflict) {
      @user_client.nodes.update(node[:_id], micro: [0.1, 0.3])
    }
    assert error.message =~ /1 tries left/i

    error = assert_raises(SynapsePayments::Error::Conflict) {
      @user_client.nodes.update(node[:_id], micro: [0.1, 0.3])
    }
    assert error.message =~ /0 tries left/i

    # Despite 0 tries in previous the node is not locked unless another call is made.
    response = @user_client.nodes.find(node[:_id])
    assert_equal 'CREDIT', response[:allowed]

    error = assert_raises(SynapsePayments::Error::Conflict) {
      @user_client.nodes.update(node[:_id], micro: [0.1, 0.3])
    }

    response = @user_client.nodes.find(node[:_id])
    assert_equal 'LOCKED', response[:allowed]

    @user_client.nodes.delete(node[:_id])
  end

  def test_add_instant_verified_bank_account
    response = @user_client.add_bank_account(name: 'John Doe', account_number: '123456786', routing_number: '051000017', category: 'PERSONAL', type: 'CHECKING')

    assert response[:success]
    assert_equal 1, response[:nodes].size
    refute_predicate response[:nodes][0][:_id], :empty?
    assert_equal 'John Doe', response[:nodes][0][:info][:name_on_account]
    assert_equal 'PERSONAL', response[:nodes][0][:info][:type]
    assert_equal 'CHECKING', response[:nodes][0][:info][:class]
    assert_equal '6786', response[:nodes][0][:info][:account_num]
    assert_equal '0017', response[:nodes][0][:info][:routing_num]

    @user_client.nodes.delete(response[:nodes].first[:_id])
  end

  def test_bank_login
    bank = @user_client.bank_login(bank_name: 'fake', username: 'synapse_nomfa', password: 'test1234')

    assert_equal 2, bank[:nodes].size
    assert_equal 'CREDIT-AND-DEBIT', bank[:nodes][0][:allowed]
    assert_equal '8901', bank[:nodes][0][:info][:account_num]
    assert_equal 'CREDIT-AND-DEBIT', bank[:nodes][1][:allowed]
    assert_equal '8902', bank[:nodes][1][:info][:account_num]
  end

  def test_bank_login_with_mfa
    bank = @user_client.bank_login(bank_name: 'fake', username: 'synapse_good', password: 'test1234')

    assert bank[:success]
    assert_nil bank[:nodes]
    refute_predicate bank[:mfa][:access_token], :empty?
    refute_predicate bank[:mfa][:message], :empty?

    bank = @user_client.verify_mfa(access_token: bank[:mfa][:access_token], answer: 'wrong answer')

    assert_nil bank[:nodes]
    refute_predicate bank[:mfa][:access_token], :empty?
    refute_predicate bank[:mfa][:message], :empty?

    bank = @user_client.verify_mfa(access_token: bank[:mfa][:access_token], answer: 'test_answer')

    assert bank[:success]
    assert_equal 2, bank[:nodes].size

    @user_client.nodes.delete(bank[:nodes].first[:_id])
  end

  # only works if the user_id has a SYNAPSE-US node already
  def test_sending_money
    response = @user_client.add_bank_account(name: 'John Doe', account_number: '123456786', routing_number: '051000017', category: 'PERSONAL', type: 'CHECKING')
    bank_node = response[:nodes].first

    idempotency_key = Time.now.to_i

    nodes = @user_client.nodes.all
    escrow_node = nodes[:nodes].select { |n| n[:type] == 'SYNAPSE-US' }.first

    transaction = @user_client.send_money(
      idempotency_key: idempotency_key,
      from: bank_node[:_id],
      to: escrow_node[:_id],
      to_node_type: 'SYNAPSE-US',
      amount: 2.00,
      currency: 'USD',
      ip_address: '192.168.0.1',
      extra: {
        supp_id: '123'
      },
      fees: [
        {
          fee: 0.05,
          note: 'Business Fee',
          to: {
            id: '559339aa86c273605ccd35df'
          }
        }
      ]
    )

    refute_predicate transaction[:_id], :empty?
    assert_equal 2.0, transaction[:amount][:amount]
    assert_equal 'USD', transaction[:amount][:currency]
    assert_equal '192.168.0.1', transaction[:extra][:ip]
    assert_equal '123', transaction[:extra][:supp_id]
    assert_equal bank_node[:_id], transaction[:from][:id]
    assert_equal escrow_node[:_id], transaction[:to][:id]
    assert_equal 2, transaction[:fees].size

    error = assert_raises(SynapsePayments::Error::Conflict) {
      transaction = @user_client.send_money(
        idempotency_key: idempotency_key,
        from: bank_node[:_id],
        to: escrow_node[:_id],
        to_node_type: 'SYNAPSE-US',
        amount: 2.00,
        currency: 'USD',
        ip_address: '192.168.0.1',
      )
    }

    assert_kind_of SynapsePayments::Error::ClientError, error
    assert error.message =~ /Idempotency key already used/i

    @user_client.nodes.delete(bank_node[:_id])
  end

end
