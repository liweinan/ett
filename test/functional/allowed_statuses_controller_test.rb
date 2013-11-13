require 'test_helper'

class AllowedStatusesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:allowed_statuses)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create allowed_status" do
    assert_difference('AllowedStatus.count') do
      post :create, :allowed_status => { }
    end

    assert_redirected_to allowed_status_path(assigns(:allowed_status))
  end

  test "should show allowed_status" do
    get :show, :id => allowed_statuses(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => allowed_statuses(:one).to_param
    assert_response :success
  end

  test "should update allowed_status" do
    put :update, :id => allowed_statuses(:one).to_param, :allowed_status => { }
    assert_redirected_to allowed_status_path(assigns(:allowed_status))
  end

  test "should destroy allowed_status" do
    assert_difference('AllowedStatus.count', -1) do
      delete :destroy, :id => allowed_statuses(:one).to_param
    end

    assert_redirected_to allowed_statuses_path
  end
end
