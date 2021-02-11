require 'spec_helper'
require 'fake_translation_class'
require 'user_editable_translations/translation_helper'

describe TranslationHelper do
  before :each do
    TranslationHelper.config(translation: FakeTranslationClass)
  end

  describe 'key_value_to_hash' do
    def key_value_to_hash(key, value)
      TranslationHelper.key_value_to_hash(key, value)
    end

    context 'key1, value1' do
      let(:hash) { key_value_to_hash('key1', 'value1') }

      specify { expect(hash).to eql({ :key1 => 'value1' }) }
    end

    context 'key1.key2, value1' do
      let(:hash) { key_value_to_hash('key1.key2', 'value1') }

      specify { expect(hash).to eql({ :key1 => { :key2 => 'value1' } }) }
    end

    context 'key1.key2.key3, value1' do
      let(:hash) { key_value_to_hash('key1.key2.key3', 'value1') }

      specify { expect(hash).to eql({ :key1 => { :key2 => { :key3 => 'value1' } } }) }
    end
  end

  describe 'translation_to_hash' do
    def translation_to_hash(translation)
      TranslationHelper.translation_to_hash(translation)
    end

    context 'locale1, key1, value1' do
      let(:translation) { FakeTranslationClass.new(locale: 'locale1', key: 'key1', value: 'value1') }
      let(:hash) { translation_to_hash(translation) }

      specify { expect(hash).to eql({ :locale1 => { :key1 => 'value1' } }) }
    end
  end

  describe 'to_dotted_hash' do
    def to_dotted_hash(hash)
      TranslationHelper.to_dotted_hash(hash)
    end

    let!(:dotted_hash) { to_dotted_hash(hash) }

    context 'hash has one embedded key' do
      let(:hash) { { :key1 => { :key2 => 'value' } } }

      specify { expect(dotted_hash).to eql({ ('key1.key2').to_sym => 'value' }) }
    end

    context 'hash has more embedded keys' do
      let(:hash) { { :key1 => { :key2 => 'value1', :key3 => 'value2' } } }

      specify { expect(dotted_hash).to eql({ ('key1.key2').to_sym => 'value1', ('key1.key3').to_sym => 'value2' }) }
    end
  end

  describe 'to_translations' do
    before :each do
      TranslationHelper.config(translation: FakeTranslationClass)
    end

    def to_translations(hash)
      TranslationHelper.to_translations(hash)
    end

    let(:translations) { to_translations(hash) }

    context 'hash has one embedded key' do
      let(:hash) { { :key1 => { :key2 => 'value' } } }

      specify { expect(translations.first.locale).to eql('key1') }

      specify { expect(translations.first.key).to eql('key2') }

      specify { expect(translations.first.value).to eql('value') }
    end

    context 'hash has more embedded keys' do
      let(:hash) { { :key1 => { :key2 => 'value1', :key3 => 'value2' } } }

      specify { expect(translations.first.key).to eql('key2') }

      specify { expect(translations.last.key).to eql('key3') }
    end
  end

  describe 'locale_from_dotted_key' do
    def locale_from_dotted_key(dotted_key)
      TranslationHelper.locale_from_dotted_key(dotted_key)
    end

    let(:locale) { locale_from_dotted_key(dotted_key) }

    context 'key is locale1.key1' do
      let(:dotted_key) { 'locale1.key1' }

      specify { expect(locale).to eql('locale1') }
    end
  end

  describe 'key_from_dotted_key' do
    def key_from_dotted_key(dotted_key)
      TranslationHelper.key_from_dotted_key(dotted_key)
    end

    let!(:key) { key_from_dotted_key(dotted_key) }

    context 'key is locale1.key1' do
      let!(:dotted_key) { 'locale1.key1' }

      specify { expect(key).to eql 'key1' }
    end
  end

  describe 'filter' do
    def filter(translations, locale = nil, scope = nil)
      TranslationHelper.filter(translations, locale, scope)
    end

    let(:translations) { {
        en: {
            scope1: 'something',
            scope2: 'other'
        },
        nl: {
            scope1: 'iets',
            scope2: 'anders'
        },
        de: {
            scope1: 'etwas'
        }
    } }
    let(:locale) { nil }
    let(:scope) { nil }
    subject { filter(translations, locale, scope) }

    specify { expect(subject).to eql(translations) }

    context 'locale is en' do
      let(:locale) { 'en' }

      specify { expect(subject).to eql({
                                           en: {
                                               scope1: 'something',
                                               scope2: 'other'
                                           }
                                       }) }

      context 'scope is scope2' do
        let(:scope) { 'scope2' }

        specify { expect(subject).to eql({ en: { scope2: 'other' } }) }
      end
    end

    context 'locale is nl' do
      let(:locale) { 'nl' }

      specify { expect(subject).to eql({
                                           nl: {
                                               scope1: 'iets',
                                               scope2: 'anders'
                                           }
                                       }) }
    end

    context 'scope is scope2' do
      let(:scope) { 'scope2' }

      specify { expect(subject).to eql({
                                           en: { scope2: 'other' },
                                           nl: { scope2: 'anders' },
                                           de: {}
                                       }) }
    end

    context 'locale is no' do
      let(:locale) { 'no' }

      specify { expect(subject).to eql({ no: nil }) }
    end
  end

  describe 'diff' do
    def diff(expectedTranslations, existingTranslations, compareValue)
      TranslationHelper.diff(expectedTranslations, existingTranslations, compareValue)
    end

    subject { diff(translations, existingTranslations, compareValue).collect { |t| t } }

    context 'set of translations' do
      let(:compareValue) { false }
      let(:translations) do
        [
          FakeTranslationClass.new(locale:'en', key:'scope1', value:'something'),
          FakeTranslationClass.new(locale:'en', key:'scope2', value:'other'),
          FakeTranslationClass.new(locale:'nl', key:'scope1', value:'iets'),
          FakeTranslationClass.new(locale:'nl', key:'scope2', value:'anders'),
          FakeTranslationClass.new(locale:'de', key:'scope1', value:'etwas')
        ]
      end

      context 'with self' do
        let(:existingTranslations) { translations }

        specify { expect(subject).to be_empty() }
      end

      context 'with equivalent set' do
        let(:existingTranslations) do
          [
            FakeTranslationClass.new(locale:'en', key:'scope1', value:'something'),
            FakeTranslationClass.new(locale:'en', key:'scope2', value:'other'),
            FakeTranslationClass.new(locale:'nl', key:'scope1', value:'iets'),
            FakeTranslationClass.new(locale:'nl', key:'scope2', value:'anders'),
            FakeTranslationClass.new(locale:'de', key:'scope1', value:'etwas')
          ]
        end

        specify { expect(subject).to be_empty() }
      end

      context 'with empty set' do
        let(:existingTranslations) { [] }

        specify { expect(subject).to match_array(translations)}
      end

      context 'with subset' do
        let(:existingTranslations) do
          [
            FakeTranslationClass.new(locale:'en', key:'scope1', value:'something'),
            FakeTranslationClass.new(locale:'en', key:'scope2', value:'other')
          ]
        end

  # For rspec matcher the objects need to be the exact objects expected (object comparison)
        let(:expectedResult) { [
          translations[2],
          translations[3],
          translations[4]
        ]}

        specify { expect(subject).to match_array(expectedResult)}
      end

      context 'with superset' do
        let(:existingTranslations) do
          [
            FakeTranslationClass.new(locale:'en', key:'scope1', value:'something'),
            FakeTranslationClass.new(locale:'en', key:'scope2', value:'other'),
            FakeTranslationClass.new(locale:'nl', key:'scope1', value:'iets'),
            FakeTranslationClass.new(locale:'nl', key:'scope2', value:'anders'),
            FakeTranslationClass.new(locale:'de', key:'scope1', value:'etwas'),
            FakeTranslationClass.new(locale:'de', key:'scope2', value:'anders')
          ]
        end

        specify { expect(subject).to be_empty() }
      end

      context 'with updated set while compareValue is false' do
        let(:existingTranslations) do
          [
            FakeTranslationClass.new(locale:'en', key:'scope1', value:'something'),
            FakeTranslationClass.new(locale:'en', key:'scope2', value:'different'),
            FakeTranslationClass.new(locale:'nl', key:'scope1', value:'iets'),
            FakeTranslationClass.new(locale:'nl', key:'scope2', value:'anders'),
            FakeTranslationClass.new(locale:'de', key:'scope1', value:'etwas'),
          ]
        end

        # For rspec matcher the objects need to be the exact objects expected (object comparison)
        let(:expectedResult) { [
          translations[1]
        ]}

        specify { expect(subject).to be_empty()}
      end
    end

    context 'empty set' do
      let(:translations) { [] }
      let(:compareValue) { false }

      context 'with self' do
        let(:existingTranslations) { translations }

        specify { expect(subject).to be_empty() }
      end

      context 'with empty set' do
        let(:existingTranslations) { [] }

        specify { expect(subject).to be_empty()}
      end

      context 'with superset' do
        let(:existingTranslations) do
          [
            FakeTranslationClass.new(locale:'en', key:'scope1', value:'something'),
            FakeTranslationClass.new(locale:'en', key:'scope2', value:'other')
          ]
        end

        specify { expect(subject).to be_empty() }
      end
    end

    context 'while compareValue is true' do
      let(:translations) do
        [
          FakeTranslationClass.new(locale:'en', key:'scope1', value:'something'),
          FakeTranslationClass.new(locale:'en', key:'scope2', value:'other'),
          FakeTranslationClass.new(locale:'nl', key:'scope1', value:'iets'),
          FakeTranslationClass.new(locale:'nl', key:'scope2', value:'anders'),
          FakeTranslationClass.new(locale:'de', key:'scope1', value:'etwas')
        ]
      end
      let(:compareValue) { true }

      context 'with updated translation' do
        let(:existingTranslations) do
          [
            FakeTranslationClass.new(locale:'en', key:'scope1', value:'something'),
            FakeTranslationClass.new(locale:'en', key:'scope2', value:'different'),
            FakeTranslationClass.new(locale:'nl', key:'scope1', value:'iets'),
            FakeTranslationClass.new(locale:'nl', key:'scope2', value:'anders'),
            FakeTranslationClass.new(locale:'de', key:'scope1', value:'etwas'),
          ]
        end

        # For rspec matcher the objects need to be the exact objects expected (object comparison)
        let(:expectedResult) { [
          translations[1]
        ]}

        specify { expect(subject).to match_array(expectedResult)}
      end

      context 'with self' do
        let(:existingTranslations) { translations }

        specify { expect(subject).to be_empty() }
      end

      context 'with empty set' do
        let(:existingTranslations) { [] }

        specify { expect(subject).to be_empty()}
      end

      context 'with subset' do
        let(:existingTranslations) do
          [
            FakeTranslationClass.new(locale:'en', key:'scope1', value:'something'),
            FakeTranslationClass.new(locale:'en', key:'scope2', value:'other')
          ]
        end

        specify { expect(subject).to be_empty() }
      end
      context 'with superset' do
        let(:existingTranslations) do
          [
            FakeTranslationClass.new(locale:'en', key:'scope1', value:'something'),
            FakeTranslationClass.new(locale:'en', key:'scope2', value:'other'),
            FakeTranslationClass.new(locale:'nl', key:'scope1', value:'iets'),
            FakeTranslationClass.new(locale:'nl', key:'scope2', value:'anders'),
            FakeTranslationClass.new(locale:'de', key:'scope1', value:'etwas'),
            FakeTranslationClass.new(locale:'de', key:'scope2', value:'anders')
          ]
        end

        specify { expect(subject).to be_empty() }
      end
      context 'with translation edited_by_user' do
        let(:existingTranslations) do
          [
            FakeTranslationClass.new(locale:'en', key:'scope1', value:'something'),
            FakeTranslationClass.new(locale:'en', key:'scope2', value:'different', edited_by_user: true),
            FakeTranslationClass.new(locale:'nl', key:'scope1', value:'iets'),
            FakeTranslationClass.new(locale:'nl', key:'scope2', value:'anders'),
            FakeTranslationClass.new(locale:'de', key:'scope1', value:'etwas'),
          ]
        end

        specify { expect(subject).to be_empty() }
      end
    end
  end
end
