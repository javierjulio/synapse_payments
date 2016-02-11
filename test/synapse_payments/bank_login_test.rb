require 'test_helper'

class BankLoginTest < Minitest::Test

  def setup
    enable_vcr!
    @user_id = '5641019d86c273308e8193f1'
  end

  def test_bank_login
    VCR.use_cassette('bank_login') do
      response = test_user_client(user_id: @user_id).bank_login(bank_name: 'fake', username: 'synapse_nomfa', password: 'test1234')

      assert_equal '200', response[:http_code]
      assert_equal '0', response[:error_code]
      assert_equal 2, response[:nodes].size
    end
  end

  def test_bank_login_with_mfa
    VCR.use_cassette('bank_login_with_mfa') do
      response = test_user_client(user_id: @user_id).bank_login(bank_name: 'fake', username: 'synapse_good', password: 'test1234')

      assert_equal '202', response[:http_code]
      assert_equal '10', response[:error_code]
      assert_equal '271b8ff8a3e73bc9f5d084f34ff4a377acf5544c3a4d021917f1f29052fbbf5d', response[:mfa][:access_token]
      assert_equal 'I heard you like questions so we put a question in your question?', response[:mfa][:message]
    end
  end

  def test_bank_login_verify_mfa
    VCR.use_cassette('bank_login_with_mfa') do
      response = test_user_client(user_id: @user_id).bank_login(bank_name: 'fake', username: 'synapse_good', password: 'test1234')

      assert_equal '202', response[:http_code]
      assert_equal '10', response[:error_code]
      assert_equal '271b8ff8a3e73bc9f5d084f34ff4a377acf5544c3a4d021917f1f29052fbbf5d', response[:mfa][:access_token]
      assert_equal 'I heard you like questions so we put a question in your question?', response[:mfa][:message]

      VCR.use_cassette('bank_login_verify_mfa') do
        response = test_user_client(user_id: @user_id).verify_mfa(access_token: response[:mfa][:access_token], answer: 'test_answer')

        assert_equal 2, response[:nodes].size
      end
    end
  end

  def test_bank_login_verify_mfa_failed
    VCR.use_cassette('bank_login_with_mfa') do
      response = test_user_client(user_id: @user_id).bank_login(bank_name: 'fake', username: 'synapse_good', password: 'test1234')

      assert_equal '202', response[:http_code]
      assert_equal '10', response[:error_code]
      assert_equal '271b8ff8a3e73bc9f5d084f34ff4a377acf5544c3a4d021917f1f29052fbbf5d', response[:mfa][:access_token]
      assert_equal 'I heard you like questions so we put a question in your question?', response[:mfa][:message]

      VCR.use_cassette('bank_login_verify_mfa_failed') do
        response = test_user_client(user_id: @user_id).verify_mfa(access_token: response[:mfa][:access_token], answer: 'wrong answer')

        assert_equal '202', response[:http_code]
        assert_equal '10', response[:error_code]
        assert_equal '271b8ff8a3e73bc9f5d084f34ff4a377acf5544c3a4d021917f1f29052fbbf5d', response[:mfa][:access_token]
        assert_equal 'I heard you like questions so we put a question in your question?', response[:mfa][:message]
      end
    end
  end

end
