require 'html-proofer'

task :test do
  options = { 
    :assume_extension => true,
    :check_favicon => true,
    :check_opengraph => true,
    :check_html => true,
    :http_status_ignore => [429],
    :only_4xx => true,
    :internal_domains => [
      'kjaer.io',
      'kjaermaxi.me'
    ],
    :cache => {
      :timeframe => '6w'
    },
    :parallel => {
      :in_processes => 2
    }
  }

  begin
    HTMLProofer.check_directory("./_site", options).run
  rescue => msg
    puts "#{msg}"
  end
end