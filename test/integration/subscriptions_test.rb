require 'test_helper'

class IntegrationSubscriptionsTest < Minitest::Test

  def setup
    skip if ENV['SYNAPSE_PAYMENTS_CLIENT_ID'].nil? || ENV['SYNAPSE_PAYMENTS_CLIENT_ID'].empty?

    disable_vcr!
  end

  def test_subscriptions
    response = authenticated_client.subscriptions.create(url: 'http://requestb.in/15zo81v1', scope: ['USERS|PATCH'])

    refute_predicate response[:_id], :empty?
    assert response[:is_active]
    assert_equal 'http://requestb.in/15zo81v1', response[:url]
    assert_equal ['USERS|PATCH'], response[:scope]

    response = authenticated_client.subscriptions.find(response[:_id])

    refute_predicate response[:_id], :empty?
    assert response[:is_active]
    assert_equal 'http://requestb.in/15zo81v1', response[:url]
    assert_equal ['USERS|PATCH'], response[:scope]

    response = authenticated_client.subscriptions.update(response[:_id], is_active: false, url: 'http://requestb.in/15zo81v1', scope: [])

    refute_predicate response[:_id], :empty?
    refute response[:is_active]
    assert_equal 'http://requestb.in/15zo81v1', response[:url]
    assert_predicate response[:scope], :empty?

    response = authenticated_client.subscriptions.all

    assert response[:success]
    assert response[:page] >= 1
    assert response[:page_count] >= 0
    refute_predicate response[:subscriptions], :empty?
    assert response[:subscriptions_count] >= 1
  end

end
