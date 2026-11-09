class AdminController < ApplicationController
  def slow
    SlowDay.on = params[:on] == "true"
    render json: { slow: SlowDay.on? }
  end
end
