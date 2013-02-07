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
end
