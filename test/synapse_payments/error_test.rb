require 'test_helper'

class ErrorTest < Minitest::Test

  def test_400_error_code
    response = {
      error: {
        en: "Unable to verify document information. Please submit a valid copy of passport/driver's license."
      },
      error_code: "400",
      http_code: "409",
      success: false
    }

    error = SynapsePayments::Error.error_from_response(response, 409)

    assert_instance_of SynapsePayments::Error::Conflict, error
    assert_kind_of SynapsePayments::Error::ClientError, error
    assert_equal "Unable to verify document information. Please submit a valid copy of passport/driver's license.", error.message
    assert_equal '400', error.code
    assert_equal response, error.response
  end

# { error: {en: "Incorrect or expired credentials."}, error_code: "110", http_code: "401", success: false}
# {:error=>{:en=>"Invalid oauth_key supplied"}, :error_code=>"110", :http_code=>"401", :success=>false}
# { error: { "en": "Unable to retrive ACH accounts associated with the bank login." }, :error_code=>"400", :http_code=>"409", :success=>nil }

end
