require 'test_helper'

class BzBugsTest < ActiveSupport::TestCase
  # Replace this with your real tests.

  def assert_for_bugzillas(bz_bug)
    assert bz_bug.bz_id == bz_info['id']
    assert bz_bug.summary == bz_info['summary']
    assert bz_bug.bz_status == bz_info['status']
    assert bz_bug.bz_assignee == bz_info['assignee']
    assert bz_bug.component == bz_info['component']
    assert bz_bug.keywords == bz_info['keywords'].join(',')
    assert bz_bug.os_arch = os
    assert bz_bug.package == Package.find(package_id)
    assert bz_bug.creator == user
  end

  test 'create_from_bz_info' do
    bz_info = {'id' => 1,
               'summary' => 'Upgrade something',
               'status' => 'MODIFIED',
               'assignee' => 'some_user',
               'component' => 'Bug',
               'keywords' => ['tom', 'sawyer']}

    os = 'el5'
    user = User.find(1)
    package_id = 1

    bz_bug = BzBug.create_from_bz_info(bz_info, package_id, user, os)

    assert bz_bug.bz_id == bz_info['id']
    assert bz_bug.summary == bz_info['summary']
    assert bz_bug.bz_status == bz_info['status']
    assert bz_bug.bz_assignee == bz_info['assignee']
    assert bz_bug.component == bz_info['component']
    assert bz_bug.keywords == bz_info['keywords'].join(',')
    assert bz_bug.os_arch = os
    assert bz_bug.package == Package.find(package_id)
    assert bz_bug.creator == user
  end

  test 'update_from_bz_info' do

    bz_info = {'id' => 1,
               'summary' => 'Upgrade something',
               'status' => 'MODIFIED',
               'assignee' => 'some_user',
               'component' => 'Bug',
               'keywords' => ['tom', 'sawyer']}

    os = 'el5'
    user = User.find(1)
    package_id = 1

    bz_bug = BzBug.first

    bz_bug.os_arch = os
    bz_bug.package = Package.find(package_id)
    bz_bug.creator = user
    bz_bug.save

    BzBug.update_from_bz_info(bz_info, bz_bug)

    assert bz_bug.bz_id == bz_info['id']
    assert bz_bug.summary == bz_info['summary']
    assert bz_bug.bz_status == bz_info['status']
    assert bz_bug.bz_assignee == bz_info['assignee']
    assert bz_bug.component == bz_info['component']
    assert bz_bug.keywords == bz_info['keywords'].join(',')
    assert bz_bug.os_arch = os
    assert bz_bug.package == Package.find(package_id)
    assert bz_bug.creator == user
  end

  test 'bz_id_and_is_in_errata' do
    bz_bug = BzBug.first
    bz_bug.bz_id = '123'
    bz_bug.is_in_errata = 'YES'

    bz_bug.save

    assert bz_bug.bz_id_and_is_in_errata == '123 ✔'

    bz_bug.is_in_errata = nil
    bz_bug.save

    assert bz_bug.bz_id_and_is_in_errata == '123'

    bz_bug.is_in_errata = 'NO'
    bz_bug.save

    assert bz_bug.bz_id_and_is_in_errata == '123'
  end
end
