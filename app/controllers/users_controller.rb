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
        createUserUrl: users_path
      }
    }

    render :new
  end

  def show
    if logged_in?
      @menu_props = {
        user: { name: current_user.name },
        urls: { logoutUrl: logout_path }
      }

      render :show
    else
      redirect_to login_path
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
