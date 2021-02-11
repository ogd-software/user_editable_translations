require 'user_editable_translations/translation_helper'

##
# Provides functionality for supporting maintenance operations on translations in the database
# Currently provides all functionality for the populate_translations tasks
class TranslationMaintenanceHelper
  def self.config(translation: Translation, simpleTranslationFileName: 'config/locales/user_editable_translations.yml')
    @@translation_class = translation
    @@simpletranslation_file = simpleTranslationFileName
  end

  def self.perform_maintenance()
    yamlTranslations = YAML.load(File.open(@@simpletranslation_file))
    translationsFromFile = TranslationHelper.to_translations(yamlTranslations)

    existingTranslations = @@translation_class.find_each

    helper = self.new()
    helper.add_missing(translationsFromFile, existingTranslations)
    helper.update_changed(translationsFromFile, existingTranslations)
    helper.delete_redundant(translationsFromFile, existingTranslations)
  end

  def add_missing(translations, existingTranslations)
    info = <<-INFO

  **************************************************************************
  * INFO: found translations in                                            *
  * 'config/locales/user_editable_translations.yml' which are not present  *
  * in the database. These will be added to the database.                  *
  **************************************************************************
  Adding:
  INFO
    info_shown = false
    TranslationHelper.diff(translations, existingTranslations).each do |translation|
      unless info_shown
        puts info
        info_shown = true
      end
      puts format_translation(translation)
      @@translation_class.create!(locale: translation.locale, key: translation.key, value: translation.value)
    end

    unless info_shown
      puts 'No missing translations found in database'
    end
  end

  def update_changed(translations, existingTranslations)
    info = <<-INFO

  **************************************************************************
  * INFO: found translations in                                            *
  * 'config/locales/user_editable_translations.yml' that differ from those *
  * in the database. These will be updated in the database.                *
  **************************************************************************
  Updating:
    INFO
    info_shown = false
    TranslationHelper.diff(translations, existingTranslations, true).each do |translation|
      unless info_shown
        puts info
        info_shown = true
      end
      puts format_translation(translation)
      @translation = @@translation_class.find_by(locale: translation.locale, key: translation.key)
      @translation.update(locale: translation.locale, key: translation.key, value: translation.value)
    end

    unless info_shown
      puts 'No out-of-date translations found in database'
    end
  end

  def delete_redundant(translations, existingTranslations)
    missingKeyDefNotification = <<-INFO

  **************************************************************************
  * INFO: found translations in database not present in                    *
  * 'config/locales/user_editable_translations.yml' with corresponding     *
  * locale and key. These will be removed from database.                   *
  **************************************************************************
  Removing:
  INFO
    notificationDisplayed = false
    TranslationHelper.diff(existingTranslations, translations).each do |translation|
      unless notificationDisplayed
        puts missingKeyDefNotification
        notificationDisplayed = true
      end
      puts format_translation(translation)
      translation.delete
    end

    unless notificationDisplayed
      puts 'No redundant translations found in database'
    end
  end

  def format_translation(translation)
    return "  - #{translation.locale}, #{translation.key}: #{translation.value}"
  end
end
