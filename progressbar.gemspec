Gem::Specification.new do |s|
  s.name = "progressbar"
  s.version = "1.0.0"
  s.author = ["Satoru Takabayashi", "Sorin Ionescu"]
  s.date = "2009-12-12"
  s.description = "Text-based progress bar for console scripts."
  s.email = ["satoru@namazu.org", "sorin.ionescu@gmail.org"]
  s.files = %w[GPL_LICENSE RUBY_LICENSE lib/progressbar.rb]
  s.homepage = "http://github.com/sorin-ionescu/progressbar"
  s.require_paths = ["lib"]
  s.add_dependency "ruby-terminfo", '>= 0.1.1'
  s.summary = <<END
ProgressBar is a text-based progress bar class for Ruby.
It can indicate progress with percentage, a progress bar,
and estimated time remaining.
END
end
