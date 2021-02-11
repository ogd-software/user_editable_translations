require 'user_editable_translations/translation_maintenance_helper'
require 'i18n/backend/active_record'

namespace :db do
  task populate_translations: :environment do
    # Get the translations from the YAML translations file.
    #
    # The user_editable_translations.yml file is (and should be) the only yml file which contains
    # the user-editable translations for the application. If you want any translatable string to
    # be changeable for the user of the application, make sure to put it in
    # 'config/locales/user_editable_translations.yml'. This includes translation keys which are
    # used by third-party gems.

    TranslationMaintenanceHelper.config(translation: I18n::Backend::ActiveRecord::Translation,
                                        simpleTranslationFileName: 'config/locales/user_editable_translations.yml')

    TranslationMaintenanceHelper.perform_maintenance()

  end
end
