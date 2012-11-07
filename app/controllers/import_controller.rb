class ImportController < ApplicationController
  before_filter :check_can_manage

  def show
    unless has_tag?(params[:id])
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
        begin
          package.from_json(package_json)
          orig_package = Package.find_by_name_and_brew_tag_id(package.name, BrewTag.find_by_name(unescape_url(params[:id])).id)

          # for Changelog.package_updated
          orig_package_clone = orig_package.clone
          orig_marks_clone = orig_package_clone.marks.clone

          if orig_package.blank?
            @not_found_packages << package
          else
            orig_package.label_id = package.label_id unless package.label_id.blank?
            if package.notes != nil && !package.notes(:plain).blank?
              package.notes(:plain).strip!

              if package.notes(:plain).match /^\+/
                str = package.notes(:plain)
                package.notes = str[1..-1]
                orig_package.notes = package.notes(:plain)+ "\r\n" + orig_package.notes(:plain)
              else
                orig_package.notes = package.notes
              end
            end

            orig_package.group_id = package.group_id unless package.group_id == nil
            orig_package.artifact_id = package.artifact_id unless package.artifact_id == nil
            orig_package.ver = package.ver unless package.ver == nil

            if orig_package.valid?
              if confirmed?
                orig_package.save!
                Changelog.package_updated(orig_package_clone, orig_package, orig_marks_clone)

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
    @final_package_names = []
    package_names.each do |pn|
      unless pn.blank?
        unless @final_package_names.index(pn.strip)
          @final_package_names << pn.strip
        end
      end
    end

    @packages = []
    @problem_packages = []
    Package.transaction do
      @final_package_names.each do |name|
        package = Package.new
        package.name = name.strip
        package.brew_tag_id = BrewTag.find_by_name(unescape_url(params[:brew_tag_id])).id
        package.created_by = current_user.id
        package.updated_by = current_user.id
        result = package.save
        if result == true
          @packages << package
        else
          @problem_packages << package
        end
      end
    end

    expire_all_fragments
  end

end
