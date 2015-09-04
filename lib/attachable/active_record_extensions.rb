module Attachable
  module ActiveRecordExtensions
    extend ActiveSupport::Concern

    def add_attachments(name, files)
      files.each do |file|
        f = self.send(name).build(data: file)
      end
    end

    def multiple?
      self.(ActiveRecord::Reflection::HasManyReflection)
    end

    module ClassMethods
      def get_caller_file_name &block
        block.send :eval, "__FILE__"
      end

      def has_attachments(name = nil, **options)
        multiple = options[:multiple]
        multiple ||= true

        reflection_method = :has_one
        reflection_method = :has_many if multiple

        name ||=  multiple ? :attachments : :attachment
        return false if self._reflections.keys.include?(name.to_s)

        send reflection_method, name, -> { where(assetable_field_name: name) }, as: :assetable, class_name: "Attachable::Asset", dependent: :destroy, autosave: true
        accepts_nested_attributes_for name
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
      end

      def has_attachment(name = nil, **options)
        options[:multiple] = false
        has_attachments(name, **options)
      end

      def has_images(name = nil, **options)
        multiple = options[:multiple]
        multiple ||= true
        name ||= multiple ? :images : :image
        has_attachments(name, **options)
      end

      def has_image(name = nil, **options)
        options[:multiple] = false
        has_images(name, **options)
      end

      def attachable?
        self._reflections.select{|key, r| r.options[:class_name] == "Asset" }.any?
      end
    end
  end
end

ActiveRecord::Base.send(:include, Attachable::ActiveRecordExtensions)

