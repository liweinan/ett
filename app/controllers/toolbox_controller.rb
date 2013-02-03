class ToolboxController < ApplicationController

  def get_pac_btns
    respond_to do |format|
      format.js
    end
  end
end
