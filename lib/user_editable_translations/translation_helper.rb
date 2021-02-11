require 'active_support'

##
# Helper functions for handling translations
class TranslationHelper

  def self.config(translation: Translation)
    @@translation_class = translation
  end

  # Returns a new hash with the key value pair
  #
  # key = 'key1', value = 'value'
  # => { :key1 => 'value' }
  #
  # If key is dot-separated (.) the hash will be built accordingly:
  # key = 'key1.key2'
  # => { :key1 => { :key2 => 'value' } }
  def self.key_value_to_hash(key, value)
    keys = key.split('.')

    keys.reverse.inject(Hash.new) do |acc, key|
      acc = acc.empty? ? { key.to_sym => value } : { key.to_sym => acc }
      acc
    end
  end

  # Returns a new hash with the user_editable_translations
  #
  # user_editable_translations.locale = 'en', user_editable_translations.key = 'key1', user_editable_translations.value = 'value'
  # => { :en => { :key1 => 'value' } }
  #
  # If key is dot-seperated (.) the hash will be build accordingly:
  # user_editable_translations.key = 'key1.key2'
  # => { :en => { :key1 => { :key2 => 'value' } } }
  def self.translation_to_hash(translation)
    { translation.locale.to_sym => key_value_to_hash(translation.key, translation.value) }
  end

  # Returns a new hash with dotted keys for the user_editable_translations
  #
  # to_dotted_hash({ :en => { :key1 => 'value' } }) => { :"en.key1" => 'value' }
  def self.to_dotted_hash(hash, recursive_key = "")
    hash.each_with_object({}) do |(k, v), ret|
      key = recursive_key + k.to_s
      if v.is_a? Hash
        ret.merge! to_dotted_hash(v, key + ".")
      else
        ret[key.to_sym] = v
      end
    end
  end

  # Returns an Array with I18n.Backend.ActiveRecord.Translation objects with parameters
  # from the hash.
  #
  # hash = { :en => { :key1 => 'value' } }
  #
  # to_translations(hash) => [<I18n.Backend.ActiveRecord.Translation>]
  def self.to_translations(hash)
    dotted_hash = to_dotted_hash(hash)
    result = []
    dotted_hash.each_key do |dotted_key|
      locale = locale_from_dotted_key(dotted_key)
      key = key_from_dotted_key(dotted_key)
      result.append (@@translation_class.new(locale: locale, key: key, value: dotted_hash[dotted_key]))
    end
    result
  end

  # Returns the locale in a dotted key
  #
  # locale_from_dotted_key(:"en.key1") => 'en'
  def self.locale_from_dotted_key(dotted_key)
    dotted_key.to_s.split('.', 2).first
  end

  # Returns the key from a dotted key
  #
  # key_from_dotted_key(:"en.key1") => 'key1'
  def self.key_from_dotted_key(dotted_key)
    dotted_key.to_s.split('.', 2).last
  end

  # Returns a filtered hash on the locale and scope
  #
  # translations = { :en => { :scope1 => 'something', :scope2 => 'other' },
  #                  :nl => { :scope1 => 'iets', :scope2 => 'anders' },
  #                  :de => { :scope1 => 'etwas' } }
  #
  # filter(translations, nil, nil) or filter(translations)
  #   => { :en => { :scope1 => 'something', :scope2 => 'other' },
  #        :nl => { :scope1 => 'iets', :scope2 => 'anders' },
  #        :de => { :scope1 => 'etwas' } }
  # filter(translations, "en", nil) or filter(translations, "en")
  #   => { :en => { :scope1 => 'something', :scope2 => 'other' } }
  # filter(translations, "en", "scope2")
  #   => { :en => { :scope2 => 'other' }
  # filter(translations, nil, "scope1")
  #   => { :en => { :scope1 => 'something' },
  #        :nl => { :scope1 => 'iets' },
  #        :de => { :scope1 => 'etwas' } }
  # filter(translations, nil, "scope2")
  #   => { :en => { :scope2 => 'other' },
  #        :nl => { :scope2 => 'anders' } }
  # filter(translations, "no", nil)
  #   => { :no => null }
  def self.filter(translations, locale = nil, scope = nil)
    filtered_result = translations
    unless locale.nil?
      filtered_result = { locale.to_sym => translations[locale.to_sym] }
    end

    unless scope.nil?
      result = {}
      filtered_result.each_key do |locale|
        value = filtered_result[locale][scope.to_sym]
        result.merge!({ locale => (value.nil? || value.empty?) ? {} : { scope.to_sym => value } })
      end
      filtered_result = result
    end
    filtered_result
  end

  # Yields translations from the expected set which have no matching locale and key in the existing set.
  # Returns enumerator for translations from the expected set which have no matching locale and key in the existing set
  # if no block is given.
  # If compareValue is TRUE, diff will also compare value of expected and existing translation, but only if the existing
  # translation has not been edited through the ActiveAdmin interface by a user.
  def self.diff(expectedTranslations, existingTranslations, compareValue = false)
    return enum_for(:diff, expectedTranslations, existingTranslations, compareValue) unless block_given?

    expectedTranslations.each do |translation|
      exists = false
      identical = false

      existingTranslations.each do |existing|
        exists = existing.locale == translation.locale && existing.key == translation.key
        if compareValue && exists
          # translations don't need to be updated if the value is identical or if it has been edited by a user in de application
          identical = existing.value == translation.value || existing.edited_by_user
        end
        break if exists
      end
      if compareValue
        if exists && !identical
          yield translation
        end
      else
        unless exists
          yield translation
        end
      end
    end
  end
end
