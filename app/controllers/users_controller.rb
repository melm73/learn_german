class UsersController < ApplicationController

  def index
     render :index, layout: 'elm'
  end


  def create
    @user = User.new(user_params)
    if @user.save
      render json: { redirectTo: root_path }, status: :created
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def new
    @user = User.new

    @signup_page_props = {
      urls: {
        createUserUrl: users_path
      }
    }

    render :new
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
