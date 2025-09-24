# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

post 'basix/configure_integration', :to => 'basix#configure_integration'
post 'basix/call_user', :to => 'basix#call_user'
