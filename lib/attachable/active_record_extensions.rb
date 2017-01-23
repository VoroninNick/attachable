module Attachable
  module ActiveRecordExtensions
    extend ActiveSupport::Concern

    def add_attachments(name, files)
      from_array = files.respond_to?(:each)

      unless files.respond_to?(:each)
        files = [files]
      end

      db_files = []

      files.each do |file|
        f = self.send(name).build(data: file)
        asset = self.send(name).last
        db_files << asset
      end

      if from_array
        return db_files
      else
        return db_files.first
      end
    end

    def multiple?
      self.(ActiveRecord::Reflection::HasManyReflection)
    end

    def reprocess!(name)

      send(name).try do |res|
        if res.is_a?(ActiveRecord::Relation)
          res.each do |asset|
            asset.reprocess! if asset.respond_to?(:reprocess!)
          end
        else
          res.reprocess! if asset.respond_to?(:reprocess!)
        end
      end

      true
    end

    def reprocess_all
      self.all_attachment_definitions.each do |name|
        if self.is_a?(ActiveRecord::Relation)
          self.each do |item|
            item.send("reprocess_#{name}!")
          end
        else
          self.send("reprocess_#{name}!")
        end


      end

      true
    end

    def all_attachment_definitions
      self.class.all_attachment_definitions
    end

    module ClassMethods
      def get_caller_file_name &block
        block.send :eval, "__FILE__"
      end

      def has_any_attachment_definitions?
        self.reflections.each do |name, reflection|
          if reflection.options[:class_name] == 'Cms::MetaTags'
            return true
          end
        end

        false
      end

      def all_attachment_definitions
        base_asset_class_name = 'Attachable::Asset'
        self.reflections.select{|name, reflection|
          reflection.options[:class_name].present? && reflection.options[:class_name] == base_asset_class_name || (Object.const_get(reflection.options[:class_name]).superclass.name == base_asset_class_name rescue false)
        }.map do |name, reflection|
          reflection.name
        end
      end

      def has_attachments(name = nil, **options)
      
        multiple = options[:multiple]
        multiple = true if multiple.nil?

      

        reflection_method = :has_one
        reflection_method = :has_many if multiple


        asset_class = options[:class_name] || options[:class] || "Attachable::Asset"

        name ||=  multiple ? :attachments : :attachment
        return false if self._reflections.keys.include?(name.to_s)

        if !has_any_attachment_definitions?
          #self.after_save :reprocess_all
        end

        send reflection_method, name, -> { where(assetable_field_name: name) }, as: :assetable, class_name: asset_class, dependent: :destroy, autosave: true
        accepts_nested_attributes_for name, allow_destroy: true
        attr_accessible name, "#{name}_attributes"

        # paperclip validation
        if !options[:validation]

        end

        # paperclip styles
        styles = options[:styles] || {}
        define_method "#{name}_styles" do
          styles
        end


        if multiple
          define_method "add_#{name}" do |attachments|
            add_attachments(name, attachments)
          end
        else
          define_method "#{name}=" do |file|
            f = self.send(name)
            f ||= self.send("build_#{name}")
            f.data = file
          end
        end

        define_method "reprocess_#{name}!" do
          reprocess!(name)
        end



        return options
      end

      def has_attachment(name = nil, **options)
        options[:multiple] = false
        has_attachments(name, options)
      end

      def has_images(name = nil, **options)
        options[:multiple] = true if options[:multiple].nil?
        name ||= options[:multiple] ? :images : :image

        has_attachments(name, options)


      end

      def has_image(name = nil, **options)
        options[:multiple] = false
        has_images(name, options)

        return options
      end

      def attachable?
        self._reflections.select{|key, r| r.options[:class_name] == "Asset" }.any?
      end
    end
  end
end

ActiveRecord::Base.send(:include, Attachable::ActiveRecordExtensions)

