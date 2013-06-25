require 'test_helper'

class CloneAntiDefaultTagSubmissionTest < ActionController::IntegrationTest
  fixtures :all


  test "do_test" do
    # login
    post "/sessions", :session => {:email => "example.com"}
    assert_response :redirect
    assert_equal session[:current_user].email, "example.com"
    assert_equal session[:current_user].id, 1
    assert !session[:current_user].blank?
    assert session[:current_user].can_manage == 'Yes'

    post "/packages/clone/default?product_id=default"
    assert_response :success
    assert_template :clone

    assert_select "div#errorExplanation" do
      assert_select "li", "Target product not found."
    end


  end
end
