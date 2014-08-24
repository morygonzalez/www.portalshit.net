require 'rack/recaptcha'

module Lokka
  module Recaptcha
    def self.registered(app)
      app.before do
        app.use Rack::Recaptcha,
          public_key:  Option.recaptcha_public_key,
          private_key: Option.recaptcha_private_key
        app.helpers Rack::Recaptcha::Helpers
        return false if request.request_method != 'POST'
        return false if request.env['PATH_INFO'] =~ /^\/admin\//

        if (params[:recaptcha_response_field].blank? || params[:recaptcha_challenge_field].blank?) ||
            (params[:recaptcha_response_field].present? && params[:recaptcha_challenge_field].present? && !recaptcha_valid?)
          halt 402, "You need to pay money to accomplish this action."
        end
      end

      app.get '/admin/plugins/recaptcha' do
        login_required
        haml :'plugin/lokka-recaptcha/views/index', :layout => :'admin/layout'
      end

      app.put '/admin/plugins/recaptcha' do
        login_required
        Option.recaptcha_public_key  = params[:recaptcha][:public_key]
        Option.recaptcha_private_key = params[:recaptcha][:private_key]
        flash[:notice] = t('recaptcha.configuration_was_successfully_updated')
        redirect '/admin/plugins/recaptcha'
      end
    end
  end
end
