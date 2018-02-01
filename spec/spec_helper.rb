##
# Load Rspec supporting files
#
Dir['./spec/support/**/*.rb'].each { |f| require f }


##
# Common Rspec configure
#
RSpec.configure do |config|
  # Turn the deprecation warnings into errors, giving you the full backtrace
  config.raise_errors_for_deprecations!
end
