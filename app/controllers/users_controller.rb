class UsersController < ApplicationController
  def create
    user = User.new(user_params)

    if user.save
      log_in(user)
      render json: { redirectTo: profile_path(id: user.id) }, status: :created
    else
      render json: user.errors, status: :unprocessable_entity
    end
  end

  def new
    @signup_page_props = {
      urls: {
        createUserUrl: users_path,
      },
    }

    render :new
  end

  def current_user_profile
    if logged_in?
      render json: { name: current_user.name, email: current_user.email }
    else
      render json: 'Access Denied', status: :unauthorized
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
