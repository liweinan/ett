require 'test_helper'

class ManualLogEntriesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:manual_log_entries)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create manual_log_entry" do
    assert_difference('ManualLogEntry.count') do
      post :create, :manual_log_entry => { }
    end

    assert_redirected_to manual_log_entry_path(assigns(:manual_log_entry))
  end

  test "should show manual_log_entry" do
    get :show, :id => manual_log_entries(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => manual_log_entries(:one).to_param
    assert_response :success
  end

  test "should update manual_log_entry" do
    put :update, :id => manual_log_entries(:one).to_param, :manual_log_entry => { }
    assert_redirected_to manual_log_entry_path(assigns(:manual_log_entry))
  end

  test "should destroy manual_log_entry" do
    assert_difference('ManualLogEntry.count', -1) do
      delete :destroy, :id => manual_log_entries(:one).to_param
    end

    assert_redirected_to manual_log_entries_path
  end
end
