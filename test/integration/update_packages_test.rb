require 'test_helper'

class UpdatePackagesTest < ActionController::IntegrationTest
  fixtures :all

  test "update packages" do

    # login
    post "/sessions", :session => {:email => "example.com"}
    assert_response :redirect
    assert_equal session[:current_user].email, "example.com"
    assert_equal session[:current_user].id, 1
    assert !session[:current_user].blank?
    assert session[:current_user].can_manage == 'Yes'

    # # enter update page
    # get "/import/default?ac=update"
    # assert_response :success
    # assert_template :edit

    # put "/import/default", {:packages => '{"name":"default","ver":"TEST","notes":"TEST"}', :confirmed => 'Yes'}
    # assert_response :success
    # assert Package.find_by_name("default").ver == 'TEST'

    # put "/import/default", {:packages => '{"name":"default","ver":"TEST","notes":"TEST3"}', :confirmed => 'Yes'}
    # assert_response :success
    # logger.info('*'*100 + Package.find_by_name("default").notes)
    # assert Package.find_by_name("default").notes(:plain) == 'TEST3'

    # put "/import/default", {:packages => '{"name":"default","ver":"TEST","notes":"+TEST4"}', :confirmed => 'Yes'}
    # assert_response :success
    # logger.info('*'*100 + Package.find_by_name("default").notes)
    # assert Package.find_by_name("default").notes(:plain) == "TEST4\nTEST3"
  end

  def logger
    RAILS_DEFAULT_LOGGER
  end
end
