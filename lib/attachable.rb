require "attachable/active_record_extensions"
require "attachable/engine"
require "rails_admin"
require "rails_admin/config/fields/types/images"

module Attachable
  @use_translations = proc { I18n.available_locales.count > 1 }

  class << self
    attr_accessor :use_translations

    def use_translations?
      if @use_translations.is_a?(Proc)
        return !!@use_translations.call
      else
        return false
      end
    end
  end
end
