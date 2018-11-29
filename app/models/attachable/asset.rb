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

  begin
    extend Enumerize
    enumerize :data_watermark_position, in: ["NorthWest", "North", "NorthEast", "West", "Center", "East", "SouthWest", "South", "SouthEast"], default: "SouthEast"
    before_save :reprocess_data_if_needed
    def reprocess_data_if_needed
      if self.respond_to?(:data_watermark_position_changed?)
        changed_position = self.data_watermark_position_changed? && self.data_watermark_position_was.present?
        puts "====================================="
        puts "====================================="
        puts "reprocess_data_if_needed"
        puts "data_watermark_position_changed?: #{data_watermark_position_changed?.inspect}"
        puts "data_watermark_position: #{data_watermark_position.inspect}"
        puts "data_watermark_position_was: #{data_watermark_position_was.inspect}"
        puts "changed_position: #{changed_position.inspect}"
        puts "====================================="
        puts "====================================="
      end

      if changed_position
        keys_to_reprocess = []
        styles = self.data.styles
        #puts "h: #{styles.inspect}"

        need_original = styles[:original].try{|s| args = s.instance_variable_get(:@other_args); args[:position].is_a?(Proc) }

        if need_original
          keys_to_reprocess = styles.keys
        end
        keys_to_reprocess = styles.map{|k, v|
          args = v.instance_variable_get(:@other_args)
          if args[:position].is_a?(Proc)
            next k
          else
            next nil
          end
        }.select(&:present?)
        puts "keys_to_reprocess: #{keys_to_reprocess.inspect}"
        if keys_to_reprocess.present?
          self.reprocess!(*keys_to_reprocess)
        end
      end
    end
  rescue
  end

  if self.table_exists? && self.column_names.include?("sorting_position")
    default_scope do
      order("sorting_position,id asc")
    end
    after_create :initialize_sorting_position
    def initialize_sorting_position
      if self.sorting_position.blank? && assetable_id.present?
        items = assetable.send(assetable_field_name).pluck(:id, :sorting_position)
        #max_item = items.map{|item| item[1] || item[0] }.max
        #count = items.count
        #if max_item

        self.sorting_position = items.last[1].try{|i| i + 1} || items.count
        self.save
      end
    end
  else
    default_scope do
      order("id asc")
    end
  end

  belongs_to :assetable, polymorphic: true

  has_attached_file :data, styles: proc {|attachment| attachment.instance.attachment_styles },
    url: "/system/attachable/assets/data/:id_partition/:style/:filename",
    path: ":rails_root/public:url"
  attr_accessible :data, :delete_data

  do_not_validate_attachment_file_type :data if respond_to?(:do_not_validate_attachment_file_type)

  # after_create {
  #   #data.reprocess!
  #
  #   true
  # }

  after_create :reprocess!

  #after_commit :reprocess!

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

  # currently not in use. it would be good if paperclip support dynamic processors like styles
  def attachment_processors
    self.assetable.try{|a| a.send("#{self.assetable_field_name}_processors") rescue nil } || {}
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
    globalize_attributes = [:data_alt] + Attachable.extra_attributes_with_translations

    translates *globalize_attributes
    accepts_nested_attributes_for :translations
    attr_accessible :translations, :translations_attributes

    class Translation
      self.table_name = :asset_translations
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

  def reprocess!(*styles)
    begin
      data.assign(data)
      data.save
    rescue
      puts "asset ##{self.id} reprocess! failed"
    end
    # if style
    #   data.reprocess!(style)
    # else
    #   data.reprocess!
    # end

    true
  end

  def create_non_existing_versions
    return if styles.blank? || !exists?

    styles.each do |style_key, style_definition|
      next if exists?(style_key)

      data.reprocess!(style_key)
    end
  end
end
