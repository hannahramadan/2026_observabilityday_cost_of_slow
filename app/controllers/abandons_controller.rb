# The chat box calls this when the customer leaves before the answer arrived.
class AbandonsController < ApplicationController
  def create
    if AskLedger.abandon(params[:id])
      head :accepted
    else
      render json: { error: "unknown question" }, status: :not_found
    end
  end
end
