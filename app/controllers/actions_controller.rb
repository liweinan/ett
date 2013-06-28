class ActionsController < ApplicationController
  before_filter :check_logged_in
  before_filter :check_product, :only => :take
  before_filter :check_can_manage, :only => [:check_clone_progress, :process_clone]
  before_filter :package_taken, :only => :take

  def take
    expire_all_fragments

    @package = Package.find_by_name_and_product_id(unescape_url(params[:id]), Product.find_by_name(unescape_url(params[:product_id])).id)
    @package.user_id = session[:current_user].id
    @package.save

    flash[:notice] = "You have taken #{@package.name} successfully."

    redirect_to(:controller => :packages, :action => :show,
                :id => escape_url(@package.name), :product_id => escape_url(@package.product.name), :user => params[:user])
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
        @source_product = Product.find_by_name(unescape_url(session[:clone_review][:source_product_name]))
        # 1. check the target product name not duplicated
        # 2. check the target product name is same within session
        target_product_name = session[:clone_review][:target_product_name].downcase.strip
        @target_product = Product.find_by_name(target_product_name)
        if !@target_product
          @target_product = Product.new
          @target_product.name = target_product_name
          @target_product.save
        end

        # clone statuses
        if session[:clone_review][:scopes].include? 'status'
          @source_product.statuses.each do |status|
            cloned_status = status.clone
            cloned_status.product = @target_product

            _status = Status.find_by_name_and_product_id(cloned_status.name, cloned_status.product.id)
            if _status
              cloned_status = _status
            else
              cloned_status.save
            end
          end
        end

        # clone tags
        if session[:clone_review][:scopes].include? 'tag'
          @source_product.tags.each do |tag|
            clone_tag = tag.clone
            clone_tag.product = @target_product
            _tag = Tag.find_by_key_and_product_id(clone_tag.key, clone_tag.product.id)
            if _tag
              clone_tag = _tag
            else
              clone_tag.save
            end
          end
        end

        # clone packages
        if session[:clone_review][:scopes].include? 'package'
          # Create new status if necessary
          @new_status = nil
          if session[:clone_review][:status_option] == 'new_value'
            @new_status = Status.new
            @new_status.name = session[:clone_review][:initial_status_value].strip
            @new_status.can_select = "Yes"
            @new_status.can_show = "Yes"
            @new_status.global = "N"
            @new_status.product = @target_product
            _status = Status.find_by_name_and_product_id(@new_status.name, @new_status.product.id)
            if _status
              @new_status = _status
            else
              @new_status.save
            end
          end

          # create new tags
          @new_tags = []
          unless session[:clone_review][:tag_options].blank?
            if session[:clone_review][:tag_options].include?('new_value')
              text_to_array(session[:clone_review][:initial_tag_values]).each do |tag_value|
                new_tag = Tag.new
                new_tag.key = tag_value
                new_tag.product = @target_product
                if new_tag.save
                  @new_tags << new_tag
                end
              end
            end
          end

          @source_product.packages.each do |source_package|
            target_package = source_package.clone
            target_package.product = @target_product

            if session[:clone_review][:scopes].include? 'assignee'
              target_package.assignee = source_package.assignee
            end

            if session[:clone_review][:status_option] == 'selection_global'
              target_package.status = Status.find_in_global_scope(session[:clone_review][:status_selection_value_global].strip, target_package.product.name)
            elsif session[:clone_review][:scopes].include?('status')
              if session[:clone_review][:status_option] == 'default'
                unless source_package.status.blank?
                  target_package.status = Status.find_in_global_scope(source_package.status.name, target_package.product.name)
                end
              elsif session[:clone_review][:status_option] == 'selection'
                target_package.status = Status.find_in_global_scope(session[:clone_review][:status_selection_value].strip, target_package.product.name)
              end
            elsif session[:clone_review][:status_option] == 'new_value'
              target_package.status = @new_status
            end

            @target_tags = []
            if session[:clone_review][:scopes].include?('tag') && product_has_tags?(source_package.product.name)
              if session[:clone_review][:tag_options].include?('default')
                source_package.tags.each do |source_tag|
                  target_tag = Tag.find_by_key_and_product_id(source_tag.key, source_package.product.id)
                  @target_tags << target_tag
                end
              end

              if session[:clone_review][:tag_options].include?('selection')
                @target_tags << process_tags(session[:clone_review][:tags], target_package.product.id)
              end
            end

            if session[:clone_review][:tag_options].include?('new_value')
              @target_tags << @new_tags
            end

            target_package.tags = @target_tags.flatten
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

      tag_clone_done
    rescue Exception => e

      tag_clone_failed(e)
    ensure
      session[:clone_review] = nil
      render :text => 'ok'
    end
  end

  protected
  def package_taken
    @package = Package.find_by_name_and_product_id(unescape_url(params[:id]), Product.find_by_name(unescape_url(params[:product_id])).id)
    if @package.user_id
      redirect_to('/')
    end
  end
end
