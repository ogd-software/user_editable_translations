class AddIndexToTranslationsUpdatedAt < ActiveRecord::Migration[4.2]
   def change
     add_index :translations, :updated_at
   end
 end
