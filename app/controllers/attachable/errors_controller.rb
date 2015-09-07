module Attachable
  class ErrorsController < ActionController::Base
    def not_found
      render inline: "<h1>404 not found</h1>", status: 404
    end
  end
end