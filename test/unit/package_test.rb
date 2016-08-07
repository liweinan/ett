# == Schema Information
#
# Table name: packages
#
#  id                        :integer          not null, primary key
#  name                      :string(255)
#  build                     :string(255)
#  notes                     :text
#  user_id                   :integer
#  created_at                :datetime
#  updated_at                :datetime
#  task_id                   :integer
#  status_id                 :integer
#  created_by                :integer
#  ver                       :string(255)
#  brew_link                 :string(255)
#  group_id                  :string(255)
#  artifact_id               :string(255)
#  project_url               :string(255)
#  project_name              :string(255)
#  license                   :string(255)
#  internal_scm              :string(255)
#  updated_by                :integer
#  status_changed_at         :datetime
#  external_scm              :string(255)
#  mead                      :string(255)
#  brew                      :string(255)
#  time_consumed             :integer
#  time_point                :integer
#  sourceURL                 :string(255)
#  RPM                       :string(255)
#  git_url                   :string(255)
#  mead_action               :string(255)
#  in_errata                 :string(255)
#  rpmdiff_status            :string(255)
#  rpmdiff_id                :string(255)
#  latest_brew_nvr           :string(255)
#  brew_scm_url              :string(255)
#  milestone                 :string(255)
#  mead_link                 :string(255)
#  errata                    :string(255)
#  maven_build_arguments     :binary
#  spec_file                 :binary
#  ini_file                  :binary
#  github_pr                 :string(255)
#  github_pr_closed          :boolean
#  previous_version          :string(255)
#  sha_ini_file              :string(255)
#  sha_spec_file             :string(255)
#  sha_maven_build_arguments :string(255)
#

require 'test_helper'

class PackageTest < ActiveSupport::TestCase

  ## Replace this with your real tests.
  #test "the truth" do
  #  package = Package.new
  #  package.name = "a"
  #  package.ptask_id = 1
  #  package.user_id = 1
  #  package.created_by = 1
  #  package.updated_by = 1
  #  package.save!
  #
  #  assert package.ptask == Task.find(1)
  #end
end
