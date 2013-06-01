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

  def get_bz_bug_edit_col
    respond_to do |format|
      format.js {
        render(:partial => 'bz_bugs/edit', :locals => {:bz_bug => BzBug.find(params[:id].scan(/\d+/))[0]})
      }
    end
  end

end
