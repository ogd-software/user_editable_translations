require 'rails/generators'
require 'rails/generators/migration'
require 'bundler'

## this generator is included specifically to updates the installation
## of UserEditableTranslations from v0.2.1 to v0.2.4, because a previously installed file needs
## to be overwritten.

module UserEditableTranslations
  class UpdateGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end

    def self.next_migration_number(dirname)
      if ActiveRecord::Base.timestamped_migrations
        Time.new.utc.strftime("%Y%m%d%H%M%S")
      else
        "%.3d" % (current_migration_number(dirname) + 1)
      end
    end

    def update_generator_to_v0_2_4
      puts "For the update to 0.2.4 we need to overwrite a few files. Please run this update on a separate branch and merge it later to make sure no work is lost."
      if !Dir.glob('config/initializers/locale.rb').empty? && Dir.glob('db/migrate/add_index_to_translations_updated_at.rb').empty?
        migration_template 'add_index_to_translations_updated_at.rb', 'db/migrate/add_index_to_translations_updated_at.rb'
        copy_file 'locale.rb', 'config/initializers/locale.rb'
      end
    end

    def update_generator_to_v0_2_6
      puts "For the update to 0.2.6 we need to overwrite your active admin translation controller. Please run this update on a separate branch and merge it later to make sure no work is lost."
      copy_file 'translation.rb', 'app/admin/translation.rb'
    end
  end
end
