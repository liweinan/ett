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

        brew_tag_name = unescape_url(params[:id])
        begin
          json_obj = JSON.parse(package_json)
          orig_package = Package.find_by_name_and_brew_tag_id(json_obj['name'], BrewTag.find_by_name(brew_tag_name).id)

          # for Changelog.package_updated
          orig_package_clone = orig_package.clone
          orig_marks_clone = orig_package_clone.marks.clone

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
            json_obj.delete(:assignee)

            #deal with label
            if json_obj['label'] != nil

              if json_obj['label'].blank?
                orig_package.label_id = nil
              else
                label = Label.find_in_global_scope(json_obj['label'], brew_tag_name)
                unless label.blank?
                  orig_package.label_id = label.id
                end
              end
            end
            json_obj.delete(:label)

            #deal with marks
            if json_obj['marks'] != nil

              if json_obj['marks'].blank?
                orig_package.marks = nil
              else
                marks = []

                json_obj['marks'].each do |mark_name|

                  unless mark_name.blank?
                    mark = Mark.find_by_key(mark_name.strip)
                    unless mark.blank?
                      marks << mark
                    end
                  end
                end

                orig_package.marks = marks
              end
            end
            json_obj.delete(:marks)

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
            json_obj.delete(:notes)

            #deal with xattrs
            json_obj.keys.each do |k|
              unless json_obj[k] == nil
                orig_package[k] = json_obj[k]
              end
            end

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
      @brew_tag = BrewTag.find_by_name(unescape_url(params[:brew_tag_id]))

      @marks = process_marks(params[:marks], @brew_tag.id)
      @label = Label.find(params[:package][:label_id]) unless params[:package][:label_id].blank?

      @final_package_names.each do |name|
        package = Package.new
        package.name = name.strip
        package.label_id = params[:package][:label_id] unless params[:package][:label_id].blank?
        package.marks = @marks unless @marks.blank?
        package.brew_tag_id = @brew_tag.id
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
