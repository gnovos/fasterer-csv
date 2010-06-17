require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|

    gem.name                      = %q{fasterer-csv}
    gem.version                   = "1.0.0"
    gem.authors                   = ["Mason"]
    gem.email                     = %q{mason@chipped.net}
    gem.date                      = Time.now.strftime("%Y-%m-%d")
    gem.description               = %q{CSV parsing awesomeness}
    gem.summary                   = %q{Even fasterer than FasterCSV!}
    gem.homepage                  = %q{http://github.com/gnovos/fasterer-csv}
    gem.post_install_message      = <<-POST
Kernel Panic!  System32 deleted!  Klaxons klaxoning!  Dogs and Cats living together!!!!  We're doooomed!  Everything is...
oh, no wait, it installed fine.  My bad.
POST

  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler you doof"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "FastererCSV #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
