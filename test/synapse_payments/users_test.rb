require 'test_helper'

class UsersTest < Minitest::Test

  def setup
    enable_vcr!
  end

  def test_users_all
    VCR.use_cassette('users_all') do
      users = test_client.users.all

      assert_equal '200', users[:http_code]
      assert_equal '0', users[:error_code]
      assert users[:success]
      refute_nil users[:users]
    end
  end

  def test_user_find
    user_id = '5641019d86c273308e8193f1'

    VCR.use_cassette('users_find') do
      user = test_client.users.find(user_id)

      assert_equal user_id, user[:_id]
      assert_equal 'refresh-95452209-3b1c-4165-a4a2-021ee96cdd32', user[:refresh_token]
      assert_equal ['Javier Julio'], user[:legal_names]
    end
  end

  def test_authenticate_as_and_user_client
    user_id = '5641019d86c273308e8193f1'
    refresh_token = 'refresh-95452209-3b1c-4165-a4a2-021ee96cdd32'

    VCR.use_cassette('oauth_refresh_token') do
      user_client = test_client.users.authenticate_as(id: user_id, refresh_token: refresh_token)

      assert_equal refresh_token, user_client.refresh_token
      assert_equal '1447445562', user_client.expires_at
      assert_equal '7200', user_client.expires_in
      assert_equal 12, user_client.refresh_expires_in
      assert_equal 'oauth_key', user_client.oauth_key

      VCR.use_cassette('users_find') do
        user = user_client.user

        assert_equal user_id, user[:_id]
        assert_equal 'refresh-95452209-3b1c-4165-a4a2-021ee96cdd32', user[:refresh_token]
        assert_equal ['Javier Julio'], user[:legal_names]
      end
    end
  end

end
