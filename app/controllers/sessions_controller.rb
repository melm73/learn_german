class SessionsController < ApplicationController

  def new
    @login_page_props = { urls: { signUpUrl: signup_path } }

    render :new
  end
end
