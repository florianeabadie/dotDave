#!/usr/bin/env ruby

require 'optparse'
require 'redcarpet'
require 'slacked'
require 'hipchat'
require 'dotenv'
require 'launchy'
require './init'

options = {}

opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: dotdave COMMAND [--last <number_days>]"
  opt.separator  ""
  opt.separator  "Commands"
  opt.separator  "     config : First thing to do to configure and start"
  opt.separator  "     open : Open the markdown file"
  opt.separator  "     send : Send to your messenger the x last reports (default : 2)"
  opt.separator  "     show : Display the x last reports (default : 2) in html"
  opt.separator  ""
  opt.separator  "Options"

  options[:days] = [1,2]
  opt.on("-l","--last NUMBER", Integer, "Set the x last reports") do |d|
    options[:days] = [1,d]
  end
  opt.on_tail("-h","--help","Help") do
    puts opt_parser
  end
  opt.parse!
end

case ARGV[0]
    when "config"
        system(ENV["SHELL_EDITOR"], '.env')

	when "open"
        system(ENV["SHELL_EDITOR"], 'reports.txt')

	when "send"
        checkConfig()
        lastdays(options[:days])
        puts File.read('temp.txt')
        print "Are you sure to send this ? [y/N]"
        $answer = STDIN.gets.chomp
        if $answer == "y" || $answer == "Y" || $answer == "yes"
            if ENV["DEFAULT_MESSENGER"] == "hipchat"
                createHtmlFile("hipchat")
                sendHipchat()
            else
                sendSlack()
            end
            puts "Successfully sent !"
        end
        File.delete("temp.txt")

    when "show"
        checkConfig()
        lastdays(options[:days])
        createHtmlFile()
        Launchy.open(File.expand_path("reports.html"))
        File.delete("temp.txt")

	else
	  	puts opt_parser
end
