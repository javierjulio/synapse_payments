require 'test_helper'

class IntegrationGeneralTest < Minitest::Test

  def setup
    skip if ENV['SYNAPSE_PAYMENTS_CLIENT_ID'].nil? || ENV['SYNAPSE_PAYMENTS_CLIENT_ID'].empty?

    disable_vcr!

    @fingerprint = ENV.fetch('SYNAPSE_PAYMENTS_FINGERPRINT')
  end

  def teardown
    @fingerprint = nil
  end

  def test_institutions
    response = authenticated_client.institutions

    assert_equal 16, response.size
    assert_equal 'Ally', response[0][:bank_name]
    assert_equal 'Bank of America', response[1][:bank_name]
  end

  def test_failure
    error = assert_raises(SynapsePayments::Error::NotFound) {
      authenticated_client.users.find('123456789')
    }

    assert_instance_of SynapsePayments::Error::NotFound, error
    assert_kind_of SynapsePayments::Error::ClientError, error
    assert_equal 'user does not exist', error.message
  end

  def test_users_all
    users = authenticated_client.users.all

    assert_equal '200', users[:http_code]
    assert_equal '0', users[:error_code]
    assert users[:success]
    refute_nil users[:users]
  end

  def test_user_create_and_user_find
    user = authenticated_client.users.create(name: 'Brian Doe', email: 'brian@test.com', phone: '646-413-8790', fingerprint: @fingerprint)

    refute_predicate user[:_id], :empty?
    refute_predicate user[:refresh_token], :empty?
    refute_predicate user[:legal_names], :empty?

    user = authenticated_client.users.find(user[:_id])

    refute_predicate user[:_id], :empty?
    refute_predicate user[:refresh_token], :empty?
    refute_predicate user[:legal_names], :empty?
  end

end
