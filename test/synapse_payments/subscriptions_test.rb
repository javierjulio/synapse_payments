require 'test_helper'

class SubscriptionsTest < Minitest::Test

  def setup
    enable_vcr!
  end

  def test_subscriptions_all
    VCR.use_cassette('subscriptions_all') do
      response = test_client.subscriptions.all

      assert_equal '200', response[:http_code]
      assert_equal '0', response[:error_code]
      assert response[:success]
      assert_equal 1, response[:page]
      assert_equal 1, response[:page_count]
      assert_equal 7, response[:subscriptions_count]
      assert_equal 7, response[:subscriptions].size
      refute_predicate response[:subscriptions], :empty?
    end
  end

  def test_subscriptions_create
    VCR.use_cassette('subscriptions_create') do
      response = test_client.subscriptions.create(url: 'http://requestb.in/15zo81v1', scope: ['USERS|PATCH'])

      assert_equal '56959cfa86c273618a4532a3', response[:_id]
      assert response[:is_active]
      assert_equal 'http://requestb.in/15zo81v1', response[:url]
      assert_equal ['USERS|PATCH'], response[:scope]
    end
  end

  def test_subscriptions_find
    subscription_id = '56959cfa86c273618a4532a3'

    VCR.use_cassette('subscriptions_find') do
      response = test_client.subscriptions.find(subscription_id)

      assert_equal subscription_id, response[:_id]
      assert response[:is_active]
      assert_equal 'http://requestb.in/15zo81v1', response[:url]
      assert_equal ['USERS|PATCH'], response[:scope]
    end
  end

  def test_subscriptions_update
    subscription_id = '56959cfa86c273618a4532a3'

    VCR.use_cassette('subscriptions_update') do
      response = test_client.subscriptions.update(subscription_id, is_active: false, url: 'http://requestb.in/15zo81v1', scope: [])

      assert_equal '56959cfa86c273618a4532a3', response[:_id]
      refute response[:is_active]
      assert_equal 'http://requestb.in/15zo81v1', response[:url]
      assert_equal [], response[:scope]
    end
  end

end
