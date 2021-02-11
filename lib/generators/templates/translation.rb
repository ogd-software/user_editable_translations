ActiveAdmin.register Translation, as: I18n.t('translation.display_name') do
  actions :all, except: [:new, :destroy]

  permit_params :value

  menu label: proc { I18n.t('translation.menu') }

  filter :locale, label: proc { I18n.t('translation.locale') }, as: :select
  filter :key, label: proc { I18n.t('translation.key') }
  filter :value, label: proc { I18n.t('translation.value') }, as: :select
  filter :edited_by_user, label: proc { I18n.t('translation.edited_by_user') }

  show title: proc { I18n.t('translation.show.title') } do |translation|
    attributes_table_for translation do
      row (I18n.t('translation.locale')) { |t| t.locale }
      row (I18n.t('translation.key')) { |t| t.key }
      row (I18n.t('translation.value')) { |t| t.value }
      row (I18n.t('translation.edited_by_user')) { |t| t.edited_by_user }
    end
  end

  index title: proc { I18n.t('translation.index.title') } do
    column I18n.t('translation.locale'), :locale
    column I18n.t('translation.key'), :key
    column I18n.t('translation.value'), :value
    column I18n.t('translation.edited_by_user'), :edited_by_user
    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :locale,
              label: I18n.t('translation.locale'),
              input_html: { readonly: true, disabled: true }
      f.input :key,
              label: I18n.t('translation.key'),
              input_html: { readonly: true, disabled: true }
      f.input :value, label: I18n.t('translation.value')
    end
    f.actions
  end

  # When saving via web interface the edited_by_user flag must be set
  # This permits us to modify the controller that ActiveAdmin generates
  # see http://activeadmin.info/docs/2-resource-customization.html#customizing-resource-retrieval
  controller do
    # Overrides standard generated update, for more information see https://github.com/josevalim/inherited_resources#overwriting-actions
    def update
      @translation = Translation.find(params[:id])
      if params[:i18n_backend_active_record_translation][:value] != @translation.value
        @translation.update(edited_by_user: true)
      end
      update!
    end
  end
end
