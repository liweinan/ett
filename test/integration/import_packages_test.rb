require 'test_helper'

class ImportPackagesTest < ActionController::IntegrationTest
  fixtures :all

  test "import packages" do
    post "/sessions", :session => {:email => "example.com"}
    assert_response :redirect
    assert_equal session[:current_user].email, "example.com"
    assert_equal session[:current_user].id, 1
    assert !session[:current_user].blank?
    assert session[:current_user].can_manage == 'Yes'

    get "/import/default"
    assert_response :success
    assert_template :show


    post "/import", {:packages => "import_package_test\r\nimport_package_test_a\r\nimport_package_test_duplicate_package\r\nimport_package_test_duplicate_package", :brew_tag_id => "default"}
    assert_response :success

    Package.all.each do |package|
      logger.info package.name
    end

    assert Package.find_by_name("import_package_test")
    assert Package.find_by_name("import_package_test_a")
    assert Package.find_by_name("import_package_test_duplicate_package")
  end

  def logger
    RAILS_DEFAULT_LOGGER
  end

end
