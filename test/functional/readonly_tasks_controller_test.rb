require 'test_helper'

class ReadonlyTasksControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:readonly_tasks)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create readonly_task" do
    assert_difference('ReadonlyTask.count') do
      post :create, :readonly_task => { }
    end

    assert_redirected_to readonly_task_path(assigns(:readonly_task))
  end

  test "should show readonly_task" do
    get :show, :id => readonly_tasks(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => readonly_tasks(:one).to_param
    assert_response :success
  end

  test "should update readonly_task" do
    put :update, :id => readonly_tasks(:one).to_param, :readonly_task => { }
    assert_redirected_to readonly_task_path(assigns(:readonly_task))
  end

  test "should destroy readonly_task" do
    assert_difference('ReadonlyTask.count', -1) do
      delete :destroy, :id => readonly_tasks(:one).to_param
    end

    assert_redirected_to readonly_tasks_path
  end
end
