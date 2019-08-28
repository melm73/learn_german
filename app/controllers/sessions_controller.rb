class SessionsController < ApplicationController

  def new
    @login_page_props = { 
      urls: { 
        signUpUrl: signup_path,
        loginUrl: login_path,
      }
    }

    render :new
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)

    if user && user.authenticate(params[:session][:password])
      # session[:current_user_id] = user.id
      render json: { redirectTo: root_path }, status: :created
    else
      render json: {}, status: :forbidden
    end
  end

  def destroy
  end
end
