require 'bundler'
Bundler::GemHelper.install_tasks

desc "Update Sublime Package"
task :sublime do
  Dir.chdir(File.dirname(__FILE__))
  pkg = ENV['HOME'] + "/sites/sublime/EPM/"
  FileUtils.cp_r( File.dirname(__FILE__) + "/lib", pkg )
  Dir.chdir(pkg)
  message = "Package updated at reflect changes in new Gem version at #{Time.now}."
  system "git add -A"
  system "git commit -m #{message.shellescape}"
  system "git push github master"
  system "git push wsl master"
  Dir.chdir(File.dirname(__FILE__))
end
