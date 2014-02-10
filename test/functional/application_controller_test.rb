require 'test_helper'

class ApplicationControllerTest < ActionController::TestCase
  def setup
    @app = ApplicationController.new
  end

  test 'should get task' do
    assert_not_nil @app.get_task('task_test')
  end

  test 'should escape url' do
    assert_nil(@app.escape_url(''))
    assert_nil(@app.escape_url(nil))
    assert_equal 'haha-dot-hoho', @app.escape_url('haha.hoho')
    assert_equal 'hoho-hoho', @app.escape_url('hoho-hoho')
    assert_equal 'haha-slash-hoho', @app.escape_url('haha/hoho')
  end

  test 'should unescape url' do
    assert_nil(@app.unescape_url(''))
    assert_nil(@app.unescape_url(nil))
    assert_equal 'haha.hoho', @app.unescape_url('haha-dot-hoho')
    assert_equal 'haha/hoho', @app.unescape_url('haha-slash-hoho')
  end

  test 'should have task?' do
    assert !@app.has_task?(nil)
    assert !@app.has_task?('task_cannot_be_found')
    assert @app.has_task?('task_test')
  end

  test 'generate request should return an empty string' do
    mock = Object.new

    def mock.port
      80
    end

    def mock.host
      'localhost'
    end

    def mock.path
      '/test'
    end

    assert @app.generate_request_path(nil) == ''
    assert_equal @app.generate_request_path(mock), 'http://localhost/test'
    assert_equal @app.generate_request_path(mock, 'frag'),
                 'http://localhost/frag'

    def mock.port
     443
    end

    assert_equal @app.generate_request_path(mock), 'http://localhost:443/test'
    assert_equal @app.generate_request_path(mock, 'frag'),
                 'http://localhost:443/frag'
  end
end