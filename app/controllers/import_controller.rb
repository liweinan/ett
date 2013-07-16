class ImportController < ApplicationController
  before_filter :check_can_manage

  def show
    unless has_task?(params[:id])
      redirect_to '/'
    end

    if params[:ac] == 'update'
      render :action => :edit
    end
  end

  def edit

  end

  def update
    @packages = []
    @cloned_packages = []
    @problem_packages = []
    @not_found_packages = []
    @parse_error_packages = Hash.new

    if confirmed?
      expire_all_fragments
    end

    Package.transaction do
      packages_in_json_format = params[:packages].split("\r\n")
      packages_in_json_format.each do |package_json|
        package = Package.new

        task_name = unescape_url(params[:id])
        begin
          json_obj = JSON.parse(package_json)
          orig_package = Package.find_by_name_and_task_id(json_obj['name'], Task.find_by_name(task_name).id)

          # for Changelog.package_updated
          orig_package_clone = orig_package.clone
          orig_tags_clone = orig_package_clone.tags.clone

          if orig_package.blank?
            @not_found_packages << package
          else
            #deal with assignee
            if json_obj['assignee'] != nil
              if json_obj['assignee'].blank?
                orig_package.assignee = nil
              else
                assignee = User.find_by_name_or_email(json_obj['assignee'])
                unless assignee.blank?
                  orig_package.assignee = assignee
                end
              end
            end
            json_obj.delete(:assignee.to_s)

            #deal with status
            if json_obj['status'] != nil

              if json_obj['status'].blank?
                orig_package.status_id = nil
              else
                status = Status.find_in_global_scope(json_obj['status'], task_name)
                unless status.blank?
                  orig_package.status_id = status.id
                end
              end
            end
            json_obj.delete(:status.to_s)

            #deal with tags
            if json_obj['tags'] != nil

              if json_obj['tags'].blank?
                orig_package.tags = nil
              else
                tags = []

                json_obj['tags'].each do |tag_name|

                  unless tag_name.blank?
                    tag = Tag.find_by_key(tag_name.strip)
                    unless tag.blank?
                      tags << tag
                    end
                  end
                end

                orig_package.tags = tags
              end
            end
            json_obj.delete(:tags.to_s)

            #deal with notes
            unless json_obj['notes'] == nil
              if json_obj['notes'].blank?
                orig_package.notes=""
              else
                json_obj['notes'].strip!

                if json_obj['notes'].match /^\+/
                  orig_package.notes = json_obj['notes'][1..-1] + "\r\n" + orig_package.notes(:plain)
                else
                  orig_package.notes = json_obj['notes']
                end
              end
            end
            json_obj.delete(:notes.to_s)

            #deal with xattrs
            json_obj.keys.each do |k|
              unless json_obj[k] == nil
                orig_package[k] = json_obj[k]
              end
            end

            if orig_package.valid?
              if confirmed?
                orig_package.save!
                Changelog.package_updated(orig_package_clone, orig_package, orig_tags_clone)

                # TODO Add url for system notification
                # notify_package_update_system_wide(url, orig_package)
              end
              @cloned_packages << orig_package_clone
              @packages << orig_package
            else
              @problem_packages << orig_package
            end
          end
        rescue => e
          @parse_error_packages[package_json] = e
        end
      end
    end
  end

  def create
    package_names = params[:packages].split("\r\n")
    @final_packages = []
    package_names.each do |pn|
      unless pn.blank?
        unless @final_packages.index(pn.strip)
          @final_packages << pn.strip
        end
      end
    end

    @packages = []
    @problem_packages = []
    Package.transaction do
      @task = Task.find_by_name(unescape_url(params[:task_id]))

      @tags = process_tags(params[:tags], @task.id)
      @status = Status.find(params[:package][:status_id]) unless params[:package][:status_id].blank?

      @bz_bugs = []

      @final_packages.each do |package_str|
        package_attr = package_str.split(",")
        package_name = package_attr[0]
        package_ver = package_attr[1]

        package = Package.new
        package.name = package_name.strip
        package.status_id = params[:package][:status_id] unless params[:package][:status_id].blank?
        package.tags = @tags unless @tags.blank?
        package.task_id = @task.id
        package.ver = package_ver
        package.created_by = current_user.id
        package.updated_by = current_user.id
        result = package.save
        if result == true
          @packages << package
          bz_bug = {:name => package_name, :ver => package_ver, :package => package}
          @bz_bugs << bz_bug
        else
          @problem_packages << package
        end
      end
    end

    if params[:create_bz] == 'on'
      BzBug.transaction do
        @bz_bugs.each do |bz_bug_obj|
          parameters = {'pkg' => bz_bug_obj[:name],
                        'version' => bz_bug_obj[:ver],
                        'release' => bz_bug_obj[:package].task.target_release,
                        'tagversion' => bz_bug_obj[:package].task.tag_version,
                        'userid' => extract_username(params[:bzauth_user]),
                        'pwd' => params[:bzauth_pwd]}
          response = Net::HTTP.post_form(bz_bug_creation_uri, parameters)
          if response.class == Net::HTTPCreated
            bug_info = extract_bz_bug_info(response.body)
            bz_bug = BzBug.new
            bz_bug.package_id = bz_bug_obj[:package].id
            bz_bug.bz_id = bug_info[:bz_id]
            bz_bug.summary = bug_info[:summary]
            bz_bug.creator_id = current_user.id
            bz_bug.save
          end
        end
      end
    end

    expire_all_fragments
  end
end
