Rails.application.routes.draw do
  get 'thumbnail', to: 'thumbnails#generate'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
