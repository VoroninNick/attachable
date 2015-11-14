# This migration comes from attachable (originally 20150901122806)
class CreateAssets < ActiveRecord::Migration
  def up
    create_table :assets do |t|
      t.integer :assetable_id
      t.string :assetable_type
      t.string :assetable_field_name
      t.has_attached_file :data

      t.string :data_alt

      t.timestamps null: false
    end

    if Attachable.use_translations?
      Attachable::Asset.create_translation_table!(data_alt: :string)
    end
  end

  def down
    if Attachable.use_translations?
      Attachable::Asset.drop_translation_table!
    end

    drop_table :assets
  end
end
