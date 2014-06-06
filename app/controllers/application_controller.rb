class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :authorize_user

  helper_method :current_user,
                :user_logged_in?,
                :omniauth_authorize_url

  serialization_scope :current_user

  rescue_from "ActiveRecord::RecordNotFound",   with: :render_not_found
  rescue_from "ActionController::RoutingError", with: :render_not_found

  private

    def render_not_found
      respond_to do |want|
        want.html {
          render file: 'public/404.html', status: 404, layout: false
        }
        want.json {
          render body: "{}", status: 404
        }
        want.all {
          render nothing: true, status: 404
        }
      end
    end


    def omniauth_authorize_url(provider, action, options = {})
      options[:do] = action
      p =  options.map{|k,v| "#{k}=#{v}" }.join("&")
      "/auth/#{provider}?#{p}"
    end

    def current_user
      @current_user ||= ::User.find_by(id: current_user_id.to_i)
    end

    def current_company
      user_logged_in? and current_user.default_company
    end

    def current_user_id
      session[:user_id]
    end

    def user_logged_in?
      !!current_user
    end

    def authorize_user
      user_logged_in? || access_denied
    end

    def access_denied
      save_location if request.format.html?

      respond_to do |want|
        want.html { render 'user_session/session/new', layout: 'session', status: 403 }
        want.json { head 403 }
        want.all  { head 403 }
      end
      false
    end

    def redirect_to_saved_location_or_root
      loc = session[:saved_location]
      redirect_to(loc || "/ui")
    end

    def save_location
      if request.fullpath != "/ui"
        session[:saved_location] = request.fullpath
      end
    end

end
