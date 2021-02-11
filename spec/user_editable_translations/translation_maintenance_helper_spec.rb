require 'spec_helper'
require 'yaml'
require 'fake_translation_class'
require 'user_editable_translations/translation_maintenance_helper'

describe TranslationMaintenanceHelper do
  before :each do
    TranslationMaintenanceHelper.config(translation: FakeTranslationClass)
  end

  # specified outside its own test scope because it also functions as a helper to others
  def format_translation(translation)
    helper = TranslationMaintenanceHelper.new
    helper.format_translation(translation)
  end

  describe 'format_translation' do
    subject { format_translation(testTranslation) }

    let(:expectedLocale) { 'locale' }
    let(:expectedKey) { 'key' }
    let(:expectedValue) { 'value' }
    let(:expectedEditedByUser) { 'edited_by_user' }
    let(:testTranslation) { FakeTranslationClass.new(locale: expectedLocale, key: expectedKey, value: expectedValue, edited_by_user: expectedEditedByUser) }

    # not using separate contexts because the output is self describing
    specify { expect(subject).to include(expectedLocale) }

    specify { expect(subject).to include(expectedKey) }

    specify { expect(subject).to include(expectedValue) }
  end

  describe 'add_missing' do
    def add_missing(translations, existingTranslations)
      helper = TranslationMaintenanceHelper.new
      helper.add_missing(translations, existingTranslations)
    end

    subject { add_missing(testTranslations, testExistingTranslations) }

    let(:testTranslations) do
      [
          FakeTranslationClass.new(locale: 'en', key: 'scope1', value: 'something', edited_by_user: false),
          FakeTranslationClass.new(locale: 'en', key: 'scope2', value: 'other', edited_by_user: false),
          FakeTranslationClass.new(locale: 'nl', key: 'scope1', value: 'iets', edited_by_user: false),
          FakeTranslationClass.new(locale: 'nl', key: 'scope2', value: 'anders', edited_by_user: false),
          FakeTranslationClass.new(locale: 'de', key: 'scope1', value: 'etwas', edited_by_user: false)
      ]
    end

    # To test stdout output the subject must be provided as a block. This way the matcher can setup to capture ouput before executing the block.
    # To test if the output includes a string the test condition must be specified as a regular expression
    context 'with no missing translations' do
      let(:testExistingTranslations) { testTranslations }

      specify { expect { subject }.to output(/No missing translations found in database/).to_stdout }
    end

    context 'with missing translations' do
      let(:testExistingTranslations) do
        [
            FakeTranslationClass.new(locale: 'en', key: 'scope1', value: 'something', edited_by_user: false),
            FakeTranslationClass.new(locale: 'en', key: 'scope2', value: 'other', edited_by_user: false),
            FakeTranslationClass.new(locale: 'nl', key: 'scope1', value: 'iets', edited_by_user: false)
        ]
      end
      context 'indicates that translations are being added' do
        specify { expect { subject }.to output(/Adding:/).to_stdout }
      end

      context 'lists all the translations being added' do
        # To ensure we always match independent of the format, the format helper is used; Its result must be escaped
        let(:firstNewTranslation) { Regexp.escape(format_translation(testTranslations[3])) }
        specify { expect { subject }.to output(/#{firstNewTranslation}/).to_stdout }

        let(:secondNewTranslation) { Regexp.escape(format_translation(testTranslations[4])) }
        specify { expect { subject }.to output(/#{secondNewTranslation}/).to_stdout }
      end

      context 'Adds missing translations' do
        # Code outputs to stdout, this is tested above and suppressed for these tests
        # The extra scope also makes the it blocks appear in the test output in the same order as in file
        before(:each) do
          $stdout = File.open(File::NULL, 'w')
        end
        after(:each) do
          $stdout = STDOUT
        end

        it 'calls create! for each new translation' do
          expect(FakeTranslationClass).to receive(:create!).exactly(2).times

          add_missing(testTranslations, testExistingTranslations)
        end

        it 'calls create! with correct parameters for the new translations' do
          expect(FakeTranslationClass).to receive(:create!).with(hash_including(:locale => 'nl', :key => 'scope2', :value => 'anders'))
          expect(FakeTranslationClass).to receive(:create!).with(hash_including(:locale => 'de', :key => 'scope1', :value => 'etwas'))

          add_missing(testTranslations, testExistingTranslations)
        end
      end
    end
  end

  describe 'update_changed' do
    def update_changed(translations, existingTranslations)
      helper = TranslationMaintenanceHelper.new
      helper.update_changed(translations, existingTranslations)
    end

    subject { update_changed(testTranslations, testExistingTranslations) }

    let(:testTranslations) do
      [
          FakeTranslationClass.new(locale: 'en', key: 'scope1', value: 'something'),
          FakeTranslationClass.new(locale: 'en', key: 'scope2', value: 'other'),
          FakeTranslationClass.new(locale: 'nl', key: 'scope1', value: 'iets'),
          FakeTranslationClass.new(locale: 'nl', key: 'scope2', value: 'anders'),
          FakeTranslationClass.new(locale: 'de', key: 'scope1', value: 'etwas')
      ]
    end

    # To test stdout output the subject must be provided as a block. This way the matcher can setup to capture ouput before executing the block.
    # To test if the output includes a string the test condition must be specified as a regular expression
    context 'with no out-of-date translations' do
      let(:testExistingTranslations) { testTranslations }

      specify { expect { subject }.to output(/No out-of-date translations found in database/).to_stdout }
    end

    context 'with out-of-date translations' do
      let(:testExistingTranslations) do
        [
            FakeTranslationClass.new(locale: 'en', key: 'scope1', value: 'something'),
            FakeTranslationClass.new(locale: 'en', key: 'scope2', value: 'else'),
            FakeTranslationClass.new(locale: 'nl', key: 'scope1', value: 'iets')
        ]
      end
      context 'indicates that translations are being updated' do
        specify { expect { subject }.to output(/Updating:/).to_stdout }
      end

      context 'lists all the translations being updated' do
        # To ensure we always match independent of the format, the format helper is used; Its result must be escaped
        let(:updatedTranslation) { Regexp.escape(format_translation(testTranslations[1])) }
        specify { expect { subject }.to output(/#{updatedTranslation}/).to_stdout }

      end

      context 'ignores new translations' do
        let(:secondNewTranslation) { Regexp.escape(format_translation(testTranslations[3])) }
        specify { expect { subject }.to_not output(/#{secondNewTranslation}/).to_stdout }

        let(:secondNewTranslation) { Regexp.escape(format_translation(testTranslations[4])) }
        specify { expect { subject }.to_not output(/#{secondNewTranslation}/).to_stdout }
      end

      context 'Updates out-of-date translations' do
        # Code outputs to stdout, this is tested above and suppressed for these tests
        # The extra scope also makes the it blocks appear in the test output in the same order as in file
        before(:each) do
          $stdout = File.open(File::NULL, 'w')
        end
        after(:each) do
          $stdout = STDOUT
        end

        it 'calls find_by for each new translation' do
          expect(FakeTranslationClass).to receive(:find_by).exactly(1).times.and_return(FakeTranslationClass.new)

          update_changed(testTranslations, testExistingTranslations)
        end
      end
    end
  end

  describe 'delete_redundant' do
    def delete_redundant(translations, existingTranslations)
      helper = TranslationMaintenanceHelper.new
      helper.delete_redundant(translations, existingTranslations)
    end

    subject { delete_redundant(testTranslations, testExistingTranslations) }

    let(:testTranslations) do
      [
        FakeTranslationClass.new(locale: 'en', key: 'scope1', value: 'something'),
        FakeTranslationClass.new(locale: 'en', key: 'scope2', value: 'other'),
        FakeTranslationClass.new(locale: 'nl', key: 'scope1', value: 'iets')
      ]
    end

    # To test stdout output the subject must be provided as a block. This way the matcher can setup to capture ouput before executing the block.
    # To test if the output includes a string the test condition must be specified as a regular expression
    context 'with no redundant translations' do
      let(:testExistingTranslations) { testTranslations }

      specify { expect { subject }.to output(/No redundant translations found in database/).to_stdout }
    end

    context 'with redundant translations' do
      let(:testExistingTranslations) do
        [
          FakeTranslationClass.new(locale: 'en', key: 'scope1', value: 'something'),
          FakeTranslationClass.new(locale: 'en', key: 'scope2', value: 'other'),
          FakeTranslationClass.new(locale: 'nl', key: 'scope1', value: 'iets'),
          FakeTranslationClass.new(locale: 'nl', key: 'scope2', value: 'anders'),
          FakeTranslationClass.new(locale: 'de', key: 'scope1', value: 'etwas')
        ]
      end
      context 'indicates that translations are being removed' do
        specify { expect { subject }.to output(/Removing:/).to_stdout }
      end

      context 'lists all the translations being removed' do
        # To ensure we always match independent of the format, the format helper is used; Its result must be escaped
        let(:firstNewTranslation) { Regexp.escape(format_translation(testExistingTranslations[3])) }
        specify { expect { subject }.to output(/#{firstNewTranslation}/).to_stdout }

        let(:secondNewTranslation) { Regexp.escape(format_translation(testExistingTranslations[4])) }
        specify { expect { subject }.to output(/#{secondNewTranslation}/).to_stdout }
      end

      context 'Removes redundant translations' do
        # Code outputs to stdout, this is tested above and suppressed for these tests
        # The extra scope also makes the it blocks appear in the test output in the same order as in file
        before(:each) do
          $stdout = File.open(File::NULL, 'w')
        end
        after(:each) do
          $stdout = STDOUT
        end

        it 'calls delete on the correct instances' do
          expect(testExistingTranslations[3]).to receive(:delete)
          expect(testExistingTranslations[4]).to receive(:delete)

          delete_redundant(testTranslations, testExistingTranslations)
        end
      end
    end
  end

  describe 'TranslationMaintenanceHelper.perform_maintenance' do
    before(:each) do
      TranslationMaintenanceHelper.config(translation: FakeTranslationClass,
                                          simpleTranslationFileName: configuredYamlFile)

      # mock file operation needed in test execution, returning a string for YAML.load to parse instead of a file
      allow(File).to receive(:open) { fakedYamlFileData }

      # Isolate the perform operation
      allow(TranslationHelper).to receive(:to_translations) { '' }
      allow_any_instance_of(TranslationMaintenanceHelper).to receive(:add_missing) { '' }
      allow_any_instance_of(TranslationMaintenanceHelper).to receive(:update_changed) { '' }
      allow_any_instance_of(TranslationMaintenanceHelper).to receive(:delete_redundant) { '' }
    end

    let(:configuredYamlFile) { 'test.yaml' }
    let(:fakedYamlFileData) { 'YAML: Fake Data' }

    context 'Loads configured user_editable_translations file' do
      it 'should open yaml file' do
        expect(File).to receive(:open).with(configuredYamlFile)
        TranslationMaintenanceHelper.perform_maintenance()
      end

      it 'should load yaml data' do
        expect(YAML).to receive(:load).with(fakedYamlFileData)
        TranslationMaintenanceHelper.perform_maintenance()
      end

      it 'should convert yaml definition to translations' do
        expect(TranslationHelper).to receive(:to_translations).with(hash_including("YAML" => "Fake Data"))
        TranslationMaintenanceHelper.perform_maintenance()
      end
    end

    context 'Loads translations from database' do
      it 'should call find_each on translation backend class' do
        expect(FakeTranslationClass).to receive(:find_each)
        TranslationMaintenanceHelper.perform_maintenance()
      end
    end

    context 'Calls helpers needed for maintenance' do
      before(:each) do
        allow(TranslationHelper).to receive(:to_translations) { expectedTranslationsFromFile }
        # Instead of updating the FakeTranslationClass it is given a stub for readability and easier checking of arguments
        allow(FakeTranslationClass).to receive(:find_each) { expectedTranslationsFromDatabase }
      end
      let(:expectedTranslationsFromFile) { 'translationsFromFile' }
      let(:expectedTranslationsFromDatabase) { 'translationsFromDatabase' }

      it 'should call add_missing with correct arguments' do
        expect_any_instance_of(TranslationMaintenanceHelper).to receive(:add_missing).with(expectedTranslationsFromFile, expectedTranslationsFromDatabase)
        TranslationMaintenanceHelper.perform_maintenance()
      end

      it 'should call delete_redundant with correct arguments' do
        expect_any_instance_of(TranslationMaintenanceHelper).to receive(:delete_redundant).with(expectedTranslationsFromFile, expectedTranslationsFromDatabase)
        TranslationMaintenanceHelper.perform_maintenance()
      end
    end
  end
end
