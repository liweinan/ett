class ActionsController < ApplicationController
  before_filter :check_logged_in
  before_filter :check_tag, :only => :take
  before_filter :check_can_manage, :only => [:check_clone_progress, :process_clone]
  before_filter :package_taken, :only => :take

  def take
    expire_all_fragments

    @package = Package.find_by_name_and_brew_tag_id(unescape_url(params[:id]), BrewTag.find_by_name(unescape_url(params[:brew_tag_id])).id)
    @package.user_id = session[:current_user].id
    @package.save

    flash[:notice] = "You have taken #{@package.name} successfully."

    redirect_to(:controller => :packages, :action => :show,
                :id => escape_url(@package.name), :brew_tag_id => escape_url(@package.brew_tag.name), :user => params[:user])
  end

  def check_clone_progress
    if clone_is_done
      flash[:notice] = "Clone finished."
      render :text => 'Done'
    elsif clone_is_failed
      flash[:notice] = "Clone failed."
      render :text => 'Failed'
    else
      render :text => Time.now
    end
  end

  def process_clone

    begin
      Package.transaction do
        session[:not_cloned_packages] = Hash.new
        session[:cloned_packages] = []
        @source_tag = BrewTag.find_by_name(unescape_url(session[:clone_review][:source_tag_name]))
        # 1. check the target tag name not duplicated
        # 2. check the target tag name is same within session
        target_tag_name = session[:clone_review][:target_tag_name].downcase.strip
        @target_tag = BrewTag.find_by_name(target_tag_name)
        if !@target_tag
          @target_tag = BrewTag.new
          @target_tag.name = target_tag_name
          @target_tag.save
        end

        # clone labels
        if session[:clone_review][:scopes].include? 'label'
          @source_tag.labels.each do |label|
            cloned_label = label.clone
            cloned_label.brew_tag = @target_tag
            
            _label = Label.find_by_name_and_brew_tag_id(cloned_label.name, cloned_label.brew_tag.id)
            if _label
              cloned_label = _label
            else
              cloned_label.save
            end
          end
        end

        # clone marks
        if session[:clone_review][:scopes].include? 'mark'
          @source_tag.marks.each do |mark|
            clone_mark = mark.clone
            clone_mark.brew_tag = @target_tag
            _mark = Mark.find_by_key_and_brew_tag_id(clone_mark.key, clone_mark.brew_tag.id)
            if _mark
              clone_mark = _mark
            else
              clone_mark.save
            end
          end
        end

        # clone packages
        if session[:clone_review][:scopes].include? 'package'
          # Create new label if necessary
          @new_label = nil
          if session[:clone_review][:label_option] == 'new_value'
            @new_label = Label.new
            @new_label.name = session[:clone_review][:initial_label_value].strip
            @new_label.can_select = "Yes"
            @new_label.can_show = "Yes"
            @new_label.global = "N"
            @new_label.brew_tag = @target_tag
            _label = Label.find_by_name_and_brew_tag_id(@new_label.name, @new_label.brew_tag.id)
            if _label
              @new_label = _label
            else
              @new_label.save
            end
          end

          # create new marks
          @new_marks = []
          unless session[:clone_review][:mark_options].blank?
            if session[:clone_review][:mark_options].include?('new_value')
              text_to_array(session[:clone_review][:initial_mark_values]).each do |mark_value|
                new_mark = Mark.new
                new_mark.key = mark_value
                new_mark.brew_tag = @target_tag
                if new_mark.save
                  @new_marks << new_mark
                end
              end
            end
          end

          @source_tag.packages.each do |source_package|
            target_package = source_package.clone
            target_package.brew_tag = @target_tag

            if session[:clone_review][:scopes].include? 'assignee'
              target_package.assignee = source_package.assignee
            end

            if session[:clone_review][:label_option] == 'selection_global'
              target_package.label = Label.find_in_global_scope(session[:clone_review][:label_selection_value_global].strip, target_package.brew_tag.name)
            elsif session[:clone_review][:scopes].include?('label')
              if session[:clone_review][:label_option] == 'default'
                unless source_package.label.blank?
                  target_package.label = Label.find_in_global_scope(source_package.label.name, target_package.brew_tag.name)
                end
              elsif session[:clone_review][:label_option] == 'selection'
                target_package.label = Label.find_in_global_scope(session[:clone_review][:label_selection_value].strip, target_package.brew_tag.name)
              end
            elsif session[:clone_review][:label_option] == 'new_value'
              target_package.label = @new_label
            end

            @target_marks = []
            if session[:clone_review][:scopes].include?('mark') && brew_tag_has_marks?(source_package.brew_tag.name)
              if session[:clone_review][:mark_options].include?('default')
                source_package.marks.each do |source_mark|
                  target_mark = Mark.find_by_key_and_brew_tag_id(source_mark.key, source_package.brew_tag.id)
                  @target_marks << target_mark
                end
              end

              if session[:clone_review][:mark_options].include?('selection')
                @target_marks << process_marks(session[:clone_review][:marks], target_package.brew_tag.id)
              end
            end

            if session[:clone_review][:mark_options].include?('new_value')
              @target_marks << @new_marks
            end

            target_package.marks = @target_marks.flatten
            target_package.p_attachments = []            
            if target_package.save
              create_clone_relationship(source_package, target_package)
              session[:cloned_packages] << target_package.name
            else              
              session[:not_cloned_packages][target_package.name] = target_package.errors.full_messages              
            end
          end
        end

      end

      mark_clone_done
    rescue Exception => e

      mark_clone_failed(e)
    ensure
      session[:clone_review] = nil
      render :text => 'ok'
    end
  end

  protected
  def package_taken
    @package = Package.find_by_name_and_brew_tag_id(unescape_url(params[:id]), BrewTag.find_by_name(unescape_url(params[:brew_tag_id])).id)
    if @package.user_id
      redirect_to('/')
    end
  end
end