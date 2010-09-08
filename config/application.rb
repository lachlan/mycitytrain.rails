require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module MyCitytrain
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Brisbane'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    
    config.generators do |g|
      g.template_engine :haml
    end
    
    ActiveRecord::Base.include_root_in_json = false
  end
end

# Dirty hack to work around the following error caused by Rails 3 renaming the FlashHash class used in Rails 2,
# which has been stored in the permanent session cookie we set for mycitytrain by Rails itself.  So we define
# the Rails 2 FlashHash class just so the session can be restored by Rails 3:
# ActionDispatch::Session::SessionRestoreError (Session contains objects whose class definition isn't available.
# Remember to require the classes for all objects kept in the session.
# (Original exception: uninitialized constant ActionController::Flash::FlashHash [NameError]))
module ActionController
  module Flash
    class FlashHash < Hash
      def initialize #:nodoc:
        super
        @used = {}
      end

      def []=(k, v) #:nodoc:
        keep(k)
        super
      end

      def update(h) #:nodoc:
        h.keys.each { |k| keep(k) }
        super
      end

      alias :merge! :update

      def replace(h) #:nodoc:
        @used = {}
        super
      end

      # Sets a flash that will not be available to the next action, only to the current.
      #
      #     flash.now[:message] = "Hello current action"
      #
      # This method enables you to use the flash as a central messaging system in your app.
      # When you need to pass an object to the next action, you use the standard flash assign (<tt>[]=</tt>).
      # When you need to pass an object to the current action, you use <tt>now</tt>, and your object will
      # vanish when the current action is done.
      #
      # Entries set via <tt>now</tt> are accessed the same way as standard entries: <tt>flash['my-key']</tt>.
      def now
        #FlashNow.new(self)
      end

      # Keeps either the entire current flash or a specific flash entry available for the next action:
      #
      #    flash.keep            # keeps the entire flash
      #    flash.keep(:notice)   # keeps only the "notice" entry, the rest of the flash is discarded
      def keep(k = nil)
        use(k, false)
      end

      # Marks the entire flash or a single flash entry to be discarded by the end of the current action:
      #
      #     flash.discard              # discard the entire flash at the end of the current action
      #     flash.discard(:warning)    # discard only the "warning" entry at the end of the current action
      def discard(k = nil)
        use(k)
      end

      # Mark for removal entries that were kept, and delete unkept ones.
      #
      # This method is called automatically by filters, so you generally don't need to care about it.
      def sweep #:nodoc:
        keys.each do |k|
          unless @used[k]
            use(k)
          else
            delete(k)
            @used.delete(k)
          end
        end

        # clean up after keys that could have been left over by calling reject! or shift on the flash
        (@used.keys - keys).each{ |k| @used.delete(k) }
      end

      def store(session, key = "flash")
        return if self.empty?
        session[key] = self
      end

      private
      # Used internally by the <tt>keep</tt> and <tt>discard</tt> methods
      #     use()               # marks the entire flash as used
      #     use('msg')          # marks the "msg" entry as used
      #     use(nil, false)     # marks the entire flash as unused (keeps it around for one more action)
      #     use('msg', false)   # marks the "msg" entry as unused (keeps it around for one more action)
      def use(k=nil, v=true)
        unless k.nil?
          @used[k] = v
        else
          keys.each{ |key| use(key, v) }
        end
      end
    end
  end
end