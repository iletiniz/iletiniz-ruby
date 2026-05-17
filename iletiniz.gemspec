# frozen_string_literal: true

require_relative "lib/iletiniz/version"

Gem::Specification.new do |spec|
  spec.name = "iletiniz"
  spec.version = Iletiniz::VERSION
  spec.authors = ["Iletiniz"]
  spec.summary = "Iletiniz API resmi Ruby SDK'si"
  spec.description = "Iletiniz API icin resmi Ruby SDK'si. Mesaj gonderimi, sablon kullanimi ve teslimat durumu sorgulama icin tip-guvenli arayuz saglar."
  spec.homepage = "https://github.com/iletiniz/iletiniz-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/iletiniz/iletiniz-ruby"
  spec.metadata["bug_tracker_uri"] = "https://github.com/iletiniz/iletiniz-ruby/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["lib/**/*", "README.md", "LICENSE", "iletiniz.gemspec"].select { |f| File.file?(f) }
  end
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.13"
end
