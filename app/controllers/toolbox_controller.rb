class ToolboxController < ApplicationController

  def get_pac_btns
    respond_to do |format|
      format.js
    end
  end

  def get_pac_form
    respond_to do |format|
      format.js
    end
  end

  def get_initial_pac_btn_switch
    respond_to do |format|
      format.js
    end
  end

  def get_manual_time_track_component
    respond_to do |format|
      format.js
    end
  end

  def get_manual_time_track_components
    respond_to do |format|
      format.js
    end
  end

  def toggle_changelog
    respond_to do |format|
      format.js
    end
  end

  def show_comment_dialog
    respond_to do |format|
      format.js
    end
  end

  def show_log_dialog
    respond_to do |format|
      format.js
    end
  end

  def log_work_done
    respond_to do |format|
      format.js
    end
  end

  def package_ajax_req
    respond_to do |format|
      format.js
    end
  end

  def maven_build_arguments_ajax_req
    respond_to do |format|
      format.js
    end
  end

  def spec_file_ajax_req
    respond_to do |format|
      format.js
    end
  end

  def verify_bz_pwd
    respond_to do |format|
      format.js {
        render :status => verify_bz_credentials(params), :text => nil
      }
    end
  end

  def submit_build
    respond_to do |format|
      format.js
    end
  end

  def edit_spec_file
    @package_id = params[:id]


    @pac = Package.find(@package_id)
    if @pac.spec_file.blank?
      @spec_file = tiny_box_helper(get_spec_file_content(@pac.name,
                                                     @pac.task.primary_os_advisory_tag.candidate_tag))
    else
      @spec_file = tiny_box_helper(@pac.spec_file)
    end

    render :layout => false
  end

  def edit_maven_build_arguments_file
    @package_id = params[:id]


    @pac = Package.find(@package_id)

    if @pac.maven_build_arguments.blank?
      @m_b_a = tiny_box_helper(get_maven_build_arguments_content(@pac.name,
                                                     @pac.task.primary_os_advisory_tag.candidate_tag))
    else
      @m_b_a = tiny_box_helper(@pac.maven_build_arguments)
    end

    render :layout => false
  end

  def edit_ini_file
    @package_id = params[:id]
    @package = Package.find(@package_id)

    if true
      branch = @package.task.primary_os_advisory_tag.candidate_tag
      ini_file = get_file_content_from_rpm_repo(@package.name, branch,
                                                "#{@package.name}.ini")
      if @package.ini_file.blank? || ini_file.blank?
        @maven_group_artifact = ''
        @build_requires = ''
        @goals = ''
        @profiles = ''
        @properties = ''
        @maven_options = ''
        @envs = ''
        @jvm_options = ''
      else
        unless pac.ini_file.blank?
          parsed = IniParse.parse(pac.ini_file)
        else
          parsed = IniParse.parse(ini_file)
        end

        config = parsed.first

        @maven_group_artifact = config.key
        @build_requires = config['buildrequires']
        @goals = config['goals']
        @profiles = config['profiles']
        @properties = config['properties']
        @maven_options = config['maven_options']
        @envs = config['envs']
        @jvm_options = config['jvm_options']
      end
      render :layout => false
    else
      # TODO: this will be disabled for now. if the ini file is present we'll
      # show it, otherwise, we'll show nothing.
      @maven_group_artifact = find_group_artifact_id(@package)
      @build_requires = ''
      @goals, @profiles, @properties = get_goals_profiles_properties(@package,
                                                     @package.task.primary_os_advisory_tag.candidate_tag)

      # advanced part
      @maven_options = ''
      @envs = ''
      @jvm_options = ''
      render :layout => false
    end
  end

  # TODO: implement
  # FIXME: handles only git for now
  def find_group_artifact_id(package)
    git_src = package.git_url.sub('git://git.app.eng.bos.redhat.com/', '')
    package_name = git_src.split('#')[0]
    commit_id = git_src.split('#')[1]

    directory = ''

    if package_name.include? '?':
      directory = package_name.split('?')[1] + '/'
      package_name = package_name.split('?')[0]
    end
    link = "http://git.app.eng.bos.redhat.com/git/#{package_name}/plain/#{directory}pom.xml?id=#{commit_id}"
    xml_pom = download_item_from_link(link)
    parsed_xml_pom = XmlSimple.xml_in(xml_pom)

    groupId = parsed_xml_pom['groupId'] || parsed_xml_pom['parent'][0]['groupId']
    "#{groupId}-#{parsed_xml_pom['artifactId']}"
  end

  # TODO: implement
  def get_goals_profiles_properties(package, branch)
    content = get_file_content_from_rpm_repo(package.name, branch, 'maven-build-arguments')
    content.gsub!("\n", " ")
    content.gsub!("\\", " ")

    items = content.split('--')
    goals = []
    properties = []
    profiles = []

    items.each do |item|
      item_sanitized = item.strip
      next if item_sanitized.empty?
      key = item_sanitized.split(" ")[0]
      value = item_sanitized.split(" ")[1]

      case key
      when "goal" then goals << value
      when "property" then properties << value
      when "profile" then profiles << value
      end

    end
    return goals, profiles, properties
  end

  def get_maven_build_arguments_content(package, branch)
    get_file_content_from_rpm_repo(package, branch, 'maven-build-arguments')
  end

  def get_spec_file_content(package, branch)
    get_file_content_from_rpm_repo(package, branch, "#{package}.spec")
  end

  def get_file_content_from_rpm_repo(package, branch, file)
    link = "http://pkgs.devel.redhat.com/cgit/rpms/#{package}/plain/#{file}?h=#{branch}"
    download_item_from_link(link)
  end

  def download_item_from_link(link)
    uri = URI(link)
    response = Net::HTTP.get_response(uri)
    response.code == "200" ? response.body : ''
  end

  def press_build_button
    @package_id = params[:id]


    @pac = Package.find(@package_id)
    @clentry = tiny_box_helper("- ")
    @error = nil

    if @pac.status.blank? || @pac.status.code != 'inprogress' || @pac.user.nil?
      @error = "You can only use the Build Button when the status is 'InProgress' and there is an assignee to this package"
    end
    render :layout => false
  end

  def tiny_box_helper(content)
    # metaprogramming
    entry = Object.new
    entry.class.module_eval { attr_accessor :text }
    entry.text = content || "- "
    entry
  end
end
