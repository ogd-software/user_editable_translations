require 'i18n/backend/active_record/translation'

class I18n::Backend::ActiveRecord::Translation
  after_update :invalidate_cache

  def invalidate_cache
    I18n.backend.reload!
  end
end
