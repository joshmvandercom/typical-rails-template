@facebook = false
@twitter = false

# Thanks to RailsWizard.org for these methods
def say_custom(tag, text); say "\033[1m\033[36m" + tag.to_s.rjust(10) + "\033[0m" + "  #{text}" end
def say_recipe(name); say "\033[1m\033[36m" + "recipe".rjust(10) + "\033[0m" + "  Running #{name} recipe..." end
def say_wizard(text); say_custom(@current_recipe || 'wizard', text) end
def ask_wizard(question)
  ask "\033[1m\033[30m\033[46m" + (@current_recipe || "prompt").rjust(10) + "\033[0m\033[36m" + "  #{question}\033[0m"
end

def yes_wizard?(question)
  answer = ask_wizard(question + " \033[33m(y/n)\033[0m")
  case answer.downcase
    when "yes", "y"
      true
    when "no", "n"
      false
    else
      yes_wizard?(question)
  end
end

def yaml_line(lib)
  lib.upcase + ' = YAML.load_file("#{Rails.root}/config/' + lib + '.yml")[Rails.env].symbolize_keys'
end

def yaml_file(lib)
    file "config/#{lib}.yml", <<-CODE
    development:
      key:
      secret:
    test:
      key:
      secret:
    production:
      key:
      secret:
    CODE
end

# Set up omniauth

omniauths = ask_wizard("Enter the omniauths you want to use ex: facebook twitter dropbox")
omniauths = omniauths.split(/\ +/)

has_omniauth = omniauths.count != 0


# Gems

gem 'haml-rails'
gem 'bootstrap-sass'

gem 'omniauth'

if has_omniauth
  for omniauth in omniauths
    gem "omniauth-#{omniauth}"
  end
end

gem 'hpricot'

gem 'uuidtools'

gem 'factory_girl_rails', :group => [ :test ]
gem 'capybara', :group => [ :test ]
gem 'shoulda', :require => false, :group => [ :test ]
gem 'shoulda-matchers', :group => [ :test ]
gem 'spork', :group => [ :test ]
gem 'guard', :group => [ :test ]
gem 'guard-spork', :group => [ :test ]

run 'bundle install'

# Set up rspec

generate 'rspec:install'

# Configuration

inject_into_file 'config/application.rb', :after => "config.filter_parameters += [:password]" do
  <<-eos
    # Customize generators
    config.generators do |g|
      g.view_specs false
      g.helper_specs false
      g.assets false
      g.helper
      g.template_engine :haml
    end
  eos
end

file 'config/config.yml', <<-CODE
    development:
      name: #{app_name}
      domain: #{app_name}dev.com
    test:
      name: #{app_name}
      domain: #{app_name}dev.com
    production:
      name: #{app_name}
      domain: #{app_name}.com
CODE


file 'config/s3.yml', <<-CODE
development:
  bucket_name:
  access_key_id:
  secret_access_key:
test:
  bucket_name:
  access_key_id:
  secret_access_key:
production:
  bucket_name:
  access_key_id:
  secret_access_key:
CODE

initializer 'a_load_configs.rb', <<-CODE
#{yaml_line('config')}
#{yaml_line('s3')}
CODE

# Create Omniauth

if has_omniauth
  for omniauth in omniauths
    say_custom('debug', omniauth)
    yaml_file(omniauth)
    append_file "config/initializers/a_load_configs.rb"  do
      yaml_line(omniauth)
    end
  end
end

# Clean Up

run 'rm -rf test'
remove_file 'public/index.html'
remove_file 'public/images/rails.png'
