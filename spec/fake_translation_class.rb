class FakeTranslationClass
  attr_accessor :locale, :key, :value, :edited_by_user

  def initialize(locale: nil, key: nil, value: nil, edited_by_user: nil)
    @locale = locale
    @key = key
    @value = value
    @edited_by_user = edited_by_user
  end

# Created to make test output more readable
  def inspect
    "<@locale=\"#{@locale}\", @key=\"#{@key}\", @value=\"#{@value}\", @edited_by_user=\"#{@edited_by_user}\">"
  end

# Below functions are stubs for ActiveRecord operations used by the translation maintenance Helper

  def self.create!(locale: nil, key: nil, value: nil, edited_by_user: nil)
    return self.new(locale: locale, key: key, value: value, edited_by_user: edited_by_user)
  end

  def self.find_by(arg)
    return self.new(locale: 'locale', key: 'key', value: 'value')
  end

  def update(nonsense)
    return 'nonsense'
  end

  def self.find_each
    return enum_for(:find_each) unless block_given?
    yield self.new(locale: 'locale', key: 'key', value: 'value')
  end

  def delete
    return self
  end

end
