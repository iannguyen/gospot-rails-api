class Api::SkinsController < ApplicationController
  before_filter :sanitize_skin_params, only: [:create]

  def index
    render json: Skin.all
  end

  def new
  end

  def create
    @skin = Skin.new(skin_params)
    if @skin.save
      render json: @skin, status: 201
    else
      render json: { failures: @skin.errors.full_messages }, status: 422
    end
  end

  def destroy
    @skin = Skin.find(params[:id])
    if @skin.payout_id
      assoc_skins = Skin.where(payout_id: @skin.payout_id).all
      assoc_skins.each do |skin|
        skin.payout_id = nil
        skin.save
      end
    end
    @skin.destroy
    render json: @skin, status: 201
  end

  private

  def skin_params
    params.require(:skin).permit(:name, :price, :user_id)
  end

  def sanitize_skin_params
    params[:skin][:user_id] = params[:skin][:user].to_i
  end
end
