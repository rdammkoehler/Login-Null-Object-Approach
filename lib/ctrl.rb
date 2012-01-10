module Scratch
  class LoginController
    def initialize authorizer
      @authorizer = authorizer
    end
    def login usr, pwd
      @authorizer.authenticate(usr).with(pwd).go :home
    end
  end
  class ProfileController
    def initialize authorizer
      @authorizer = authorizer
    end
    def visit usr, pwd
      @authorizer.authenticate(usr).with(pwd).go :settings
    end
  end
  class Authorizer
    def initialize repository
      @repository = repository
    end
    def authenticate usr
      user_auth_info_array = @repository.get(usr)
      AuthenticationToken.new(*user_auth_info_array)
    end

  end
  class AuthRepository
    def initialize users, routes
      @users = users
      @routes = routes
    end
    def get identity
      user = @users.find(identity)
      authentication_values_array = []
      authentication_values_array << user.password
      routes_hash = Hash.new
      @routes.find(:user => user.id).each { |key,path| routes_hash[key] = path }
      [ authentication_values_array, routes_hash ]
    end
  end
  class AuthenticationToken
    def initialize authentication_values, routes
      @auth_map = Hash.new
      @auth_map.default = get_forbidden_default_routes
      authentication_values.each { |auth_val| @auth_map[auth_val] = get_forbidden_default_routes.merge(routes) }
    end
    def with validation
      Router.new @auth_map[validation]
    end
    private 
    def get_forbidden_default_routes
      @@forbidden_default_routes ||= lambda { h = Hash.new; h.default = "/403-forbidden.html"; h }.call
    end
  end
  class Router
    def initialize routes
      @routes = routes
    end
    def go route
      @routes[route]
    end
  end
  class Users
    def initialize identities
      @identities = identities
    end
    def find identity
      @identities[identity]
    end
  end
  class User
    attr_accessor :id, :name, :password
    def initialize id, name, password
      @id = id
      @name = name
      @password = password
    end
  end
  class Routes
    def initialize routes
      @routes = routes
    end
    def find filter
      @routes[filter[:user]] #contrived
    end
  end
end

#demo
USER = "rich"
PASSWORD = "password"

user = ::Scratch::User.new 1, USER, PASSWORD
test_routes = Hash[ :home => "/index.html", :settings => "/profile.html" ]
identities = Hash[ USER, user ]
users = ::Scratch::Users.new identities
routes_table = Hash[ user.id, test_routes ]
routes = ::Scratch::Routes.new routes_table
repo = ::Scratch::AuthRepository.new users, routes
authorizer = ::Scratch::Authorizer.new repo
lc = ::Scratch::LoginController.new authorizer
pc = ::Scratch::ProfileController.new authorizer

path = lc.login USER, PASSWORD
puts "redirect to #{path} after login"

path = pc.visit USER, PASSWORD
puts "redirect to #{path} after ProfileController.visit"

path = authorizer.authenticate(USER).with(PASSWORD).go :non_existent
puts "redirect to #{path} for :non_existent"
