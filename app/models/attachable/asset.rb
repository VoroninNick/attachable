# == Schema Information
#
# Table name: assets
#
#  id                   :integer          not null, primary key
#  assetable_id         :integer
#  assetable_type       :string
#  assetable_field_name :string
#  data_file_name       :string
#  data_content_type    :string
#  data_file_size       :integer
#  data_updated_at      :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
require "paperclip"
class Attachable::Asset < ActiveRecord::Base
  self.table_name = :assets
  attr_accessible *attribute_names

  belongs_to :assetable, polymorphic: true

  has_attached_file :data, styles: proc {|attachment| attachment.instance.attachment_styles }#, path:
  attr_accessible :data, :delete_data

  do_not_validate_attachment_file_type :data

  #delegate :path, :exists?, :styles, to: :data

  #before_save

  def path(style = nil)
    #data.reprocess!
    #data.path(style)
    full_path = Attachable.base_path + data.url(style)
    full_path_suffix_index = full_path.index("?")
    full_path[full_path_suffix_index, full_path.length] = ''
    full_path
  end

  def exists?(style = nil)
    original_full_path = path
    full_path = path(style)

    #if File.exists?(original_full_path) && !File.exists?(full_path)
    #  data.reprocess!
    #end

    File.exists?(full_path)
  end

  def url(style = nil)
    data.try do |data|
      domain_str = ""
      domain_str = "//#{Attachable.assets_domain}" if Attachable.assets_domain?
      #if data.exists? && !data.exists?(style)
      #data.reprocess!
      #end
      "#{domain_str}#{data.url(style)}"
    end
  end

  def attachment_styles
    self.assetable.try{|a| a.send("#{self.assetable_field_name}_styles") rescue nil } || {}
  end

  def styles
    attachment_styles
  end

  def file_name_fallback
    data_file_name
  end

  #self.before_save :check_rename

  def check_rename
    if data_file_name_changed?
      rename(data_file_name, data_file_name_was)
    end


  end

  def file_name_fallback=(value)
    new_data_file_name = value
    #rename(new_data_file_name)

    #self.data_file_name = value

    if data_file_name.blank?
      new_data_file_name = self.data_file_name
    else
      new_name = value
      #rename(new_name)
    end
  end

  attr_accessible :file_name_fallback

  def rename(new_name, old_name = nil)

    begin
    old_name ||= data_file_name
    (attachment_styles.keys+[:original]).uniq.each do |style_name|
      old_path = self.data.path(style_name)
      dir = File.dirname(old_path)
      new_path = "#{dir}/#{new_name}"

      FileUtils.mv(old_path, new_path)

    end

    rescue

    end


  end


  if Attachable.use_translations?

    translates :data_alt
    accepts_nested_attributes_for :translations
    attr_accessible :translations, :translations_attributes

    class Translation
      self.table_name = :asset_translations
      attr_accessible *attribute_names

      rails_admin do
        field :locale, :hidden
        field :data_alt
      end
    end

  end

  def self.configure_rails_admin(config)
    config.model Attachable::Asset do
      visible false

      #edit do
      field :assetable do
        hide
      end

      field :assetable_field_name do
        hide
      end

      field :data

      field :file_name_fallback, :string do
        hide
        label do
          ActiveRecord::Base.human_attribute_name(:data_file_name)
        end
      end
      if Attachable.use_translations?
        field :translations, :globalize_tabs
      end
      #end
    end
  end


end
