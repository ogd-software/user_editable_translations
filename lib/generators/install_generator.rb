require 'rails/generators'
require 'rails/generators/migration'
require 'bundler'

module UserEditableTranslations
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end

    def add_i18n_active_record_dependency
      gem 'i18n-active_record',
          github: 'svenfuchs/i18n-active_record',
          require: 'i18n/active_record'
    end

    def add_activeadmin_dependency
      gem 'activeadmin'
    end

    def add_activeadmin_addons_dependency
      gem 'activeadmin_addons'
    end

    def self.next_migration_number(dirname)
      if ActiveRecord::Base.timestamped_migrations
        curnr = current_migration_number(dirname).to_i
        timenr = Time.new.utc.strftime("%Y%m%d%H%M%S").to_i
        if curnr == timenr
          curnr + 1
        else
          timenr
        end
      else
        "%.3d" % (current_migration_number(dirname) + 1)
      end
    end

    def create_migration_file
      migration_template 'migration.rb', 'db/migrate/create_translations.rb'
    end

    def create_index_migration_file
      migration_template 'add_index_to_translations_updated_at.rb', 'db/migrate/add_index_to_translations_updated_at.rb'
    end

    def add_translation_yaml_file
      copy_file 'user_editable_translations.yml', 'config/locales/user_editable_translations.yml'
    end

    def add_locale_initializer
      copy_file 'locale.rb', 'config/initializers/locale.rb'
    end

    def add_populate_translations_task
      copy_file 'populate_translations.rake', 'lib/tasks/populate_translations.rake'
    end

    def add_translation_to_active_admin
      copy_file 'translation.rb', 'app/admin/translation.rb'
    end

    def add_translations_controller
      copy_file 'translations_controller.rb', 'app/controllers/translations_controller.rb'
    end

    def add_routes
      translations_route = <<ROUTE

  # Optional:
  #   :locale parameter : Locale parameter defines the expected locale. The locale is expected
  #                       to be in the form of 'en' or 'en-US'.
  #   :scope parameter  : Scope parameter defines the scope for the returned translations.
  #
  # Examples:
  #   { locale: 'en-US', scope: 'date' }
  #     => /en-US/translations/date
  #   { locale: nil, scope: 'date' }
  #     => /translations/date
  #   { locale: 'en-US', scope: nil }
  #     => /en-US/translations
  #   { locale: nil, scope: nil }
  #     => /translations
  # More info: http://rorlab.org/rails_guides/i18n.html#setting-the-locale-from-the-url-params
  scope '(:locale)' do
    get 'translations(/:scope)' => 'translations#index',
        as: :translations,
        constraints: { locale: /[a-z]{2}(-[A-Z]{2})?/ }
  end

ROUTE
      route translations_route
    end

    def bundle_install
      puts `bundle install`
    end

    def install_activeadmin_addons
      generate "activeadmin_addons:install"
    end
  end
end
