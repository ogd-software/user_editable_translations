require 'i18n/backend/active_record'
require 'user_editable_translations/translation'
require 'user_editable_translations/translation_helper'

# This disables the warning:
# "[deprecated] I18n.enforce_available_locales will default to true in the future. If you really
# want to skip validation of your locale you can set I18n.enforce_available_locales = false to
# avoid this message."
#
# More info: http://stackoverflow.com/questions/20361428/rails-i18n-validation-deprecation-warning
#
# We use several libraries which expect old behaviour (railties, activesupport and rack among others)
# so best is to set this false for now.
I18n.enforce_available_locales = false
I18n.default_locale = :en

Translation = I18n::Backend::ActiveRecord::Translation
TranslationHelper.config(translation: Translation)

# Wraps I18n::Backend::Memoize and adds auto-flushing behavior.
# https://github.com/svenfuchs/i18n/blob/master/lib/i18n/backend/memoize.rb#L29
module AutoFlushMemoize
  @@last_checked_at = DateTime.now
  @@last_flushed_at = DateTime.now

  def lookup(locale, key, scope = nil, options = {})
    # Don't check for updates on *every* translation lookup, that would be quite spammy.
    # Only check once per minute (at most).
    if @@last_checked_at < 1.minute.ago
      @@last_checked_at = DateTime.now

      # Check if there are any Translations that were updated_at more recently
      # than the last time that we flushed I18n::Backend::Memoize's cache.
      unless ActiveRecord::Base.connection.index_exists?(Translation.table_name, :updated_at)
        raise "Please make sure that #{Translation.table_name}.updated_at has an index"
      end
      last_updated_at = Translation.maximum(:updated_at)
      if last_updated_at && last_updated_at > @@last_flushed_at
        # Yep, there's something new in the translations table.
        # Flush I18n::Backend::Memoize's cache.
        reset_memoizations!
      end
    end

    def reset_memoizations!(locale=nil)
      @@last_flushed_at = DateTime.now
      super
    end

    # When all is done, return whatever I18n::Backend::Memoize#lookup returns.
    super
  end
end

# This initializer will be hit while running migrations, to make sure I18n is not started
# and hits the database (which will cause an error during migration time), this should
# only be run when Translations.table does exist.
if Translation.table_exists?
  # Enabling caching, the Cache module should be included in the ActiveRecord
  # and Simple backend.
  I18n::Backend::ActiveRecord.send(:include, I18n::Backend::Memoize)
  I18n::Backend::ActiveRecord.send(:include, AutoFlushMemoize)
  I18n::Backend::ActiveRecord.send(:include, I18n::Backend::Flatten)
  I18n::Backend::Simple.send(:include, I18n::Backend::Memoize)
  I18n::Backend::Simple.send(:include, I18n::Backend::Pluralization)

  # Chaining backends. Primary backend is the database (ActiveRecord). Secondary backend (Simple) is YAML files.
  # There could be any number of yml files with translations in 'config/locales/',
  # which will all be added by the Simple backend to the translation chain. That is,
  # if a translation key is not found in the ActiveRecord backend, it will be searched for in the yml files.
  I18n.backend = I18n::Backend::Chain.new(I18n::Backend::ActiveRecord.new, I18n::Backend::Simple.new)
end
