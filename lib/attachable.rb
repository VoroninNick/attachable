require "attachable/active_record_extensions"
require "attachable/engine"
require "rails_admin"
require "rails_admin/config/fields/types/images"

module Attachable
  @use_translations = proc { ActiveRecord::Base.respond_to?(:translates?) && I18n.available_locales.count > 1 }
  @subdomain = false
  @assets_domain = false

  class << self
    attr_accessor :use_translations
    attr_accessor :subdomain
    attr_accessor :assets_domain
    attr_accessor :base_path
    def use_translations?
      if @use_translations.is_a?(Proc)
        return !!@use_translations.call
      else
        return !!@use_translations
      end
    end

    def subdomain?
      !!@subdomain && @subdomain.present?
    end

    def assets_domain?
      !!@assets_domain && @assets_domain.present?
    end

    def base_path
      @base_path = Rails.root.join("public").to_s if @base_path.blank?
      @base_path
    end
  end
end
