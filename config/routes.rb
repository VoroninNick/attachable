Attachable::Engine.routes.draw do
  #if defined?(Attachable) && Attachable.subdomain?
    constraints subdomain: "assets" do
      match "(*args)", controller: :errors, action: "not_found", via: [:get, :post, :update, :put, :delete]
    end
  #end
end
