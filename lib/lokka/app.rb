# frozen_string_literal: true

require 'lokka'

module Lokka
  class App < Sinatra::Base
    include Padrino::Helpers::TranslationHelpers

    configure do
      enable :method_override, :raise_errors, :static
      YAML::ENGINE.yamler = 'syck' if YAML.const_defined?(:ENGINE)
      register Padrino::Helpers
      register Sinatra::Cache
      set :app_file, __FILE__
      set :root, File.expand_path('../../..', __FILE__)
      set public_folder: proc { File.join(root, 'public') }
      set views: proc { public_folder }
      set theme: proc { File.join(public_folder, 'theme') }
      set supported_templates: %w[erb haml :slim erubis]
      set supported_stylesheet_templates: %w[scss sass]
      set supported_javascript_templates: %w[coffee]
      set :scss, Compass.sass_engine_options
      set :sass, Compass.sass_engine_options
      set :per_page, 10
      set :admin_per_page, 200
      set :default_locale, 'en'
      set :haml, attr_wrapper: '"'
      set :protect_from_csrf, true
      supported_stylesheet_templates.each do |style|
        set style, style: :compressed
      end
      ::I18n.load_path += Dir["#{root}/i18n/*.yml"]
      helpers Lokka::Helpers
      helpers Lokka::RenderHelper
      use Rack::Session::Cookie,
        expire_after: 60 * 60 * 24 * 12,
        secret: ENV['SESSION_SECRET'],
        old_secret: ENV['OLD_SESSION_SECRET']
      use RequestStore::Middleware
      register Sinatra::Flash
      Lokka.load_plugin(self)
      Lokka::Database.new.connect
    end

    configure :production do
      set :cache_output_dir, -> { "#{public_folder}/system/cache/" }
      require 'newrelic_rpm'
      NewRelic::Agent.after_fork(force_reconnect: true)
      require 'rack/ssl-enforcer'
      use Rack::SslEnforcer, except_agents: /ELB-HealthChecker/
    end

    configure :development do
      register Sinatra::Reloader
      supported_stylesheet_templates.each do |style|
        set style, style: :expanded
      end
      enable :logging
      file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
      file.sync = true
      use Rack::CommonLogger, file
      require 'better_errors'
      use BetterErrors::Middleware
      BetterErrors.application_root = __dir__
      DataMapper::Logger.new('log/datamapper.log', :debug)
    end

    require 'lokka/app/admin.rb'
    require 'lokka/app/entries.rb'

    not_found do
      if custom_permalink?
        return redirect(request.path.sub(%r{/$}, '')) if %r{/$}.match?(request.path)

        correct_path = custom_permalink_fix(request.path)
        return redirect(correct_path) if correct_path

        @entry = custom_permalink_entry(request.path)
        status 200
        return setup_and_render_entry if @entry

        status 404
      end

      render404 = render_any('404', layout: false)
      return render404 if render404

      haml :"404", views: 'public/lokka', layout: false
    end

    error do
      'Error: ' + env['sinatra.error'].name
    end

    get '/*.css' do |path|
      content_type 'text/css', charset: 'utf-8'
      render_any path.to_sym, views: settings.views
    end

    get '/*.js' do |path|
      content_type 'text/javascript', charset: 'utf-8'
      render_any path.to_sym, views: settings.views
    end

    run! if app_file == $PROGRAM_NAME
  end
end
