require 'user_editable_translations/translation_helper'
require 'i18n/backend'
require 'active_support'

class TranslationsController < ApplicationController
  respond_to :json
  def index
    # It is not possible to get all translations from the Simple(YAML) and the
    # ActiveRecord backend simultaneously. Therefore we have to retrieve both
    # separately from each other, and deep_merge them to mimic the effects of
    # the chaining done by I18n library.

    # Get the translations from the Simple(YAML) backend, which is set as last in the
    # I18n::Backend::Chain (see: /config/initializers/locale.rb).
    I18n.backend.backends.last.send(:load_translations)
    @translations = I18n.backend.backends.last.send(:translations)

    # Get the translations from ActiveRecord.
    Translation.find_each do |translation|
      # Merge the Simple translations with the ActiveRecord translations.
      # Translations in ActiveRecord will prevail over translations from the Simple backend.
      @translations.deep_merge!(TranslationHelper.translation_to_hash(translation))
    end

    # Filter translations on requested locale.
    locale = params[:locale]
    scope = params[:scope]
    @translations = TranslationHelper.filter(@translations, locale, scope)

    render json: {
                   _links: {
                     self: {
                       href: translations_path(locale: locale, scope: scope)
                     }
                   },
                   translations: @translations
                 }
  end
end
