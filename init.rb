#!/usr/bin/env ruby
Dotenv.load

if not File.exist?('reports.txt')
    out_file = File.new("reports.txt", "w")
    out_file.puts(
    	"### Your date\n* installing dotdave\n* enjoying it !"
    )
    out_file.close
end

# Markdown parser
options = {
	filter_html:     true,
	hard_wrap:       true,
	link_attributes: { rel: 'nofollow', target: "_blank" },
	space_after_headers: true,
	fenced_code_blocks: true,
	prettify: true
}
extensions = {
    autolink:           true,
    superscript:        true,
    disable_indented_code_blocks: true
}
# Initializes a Markdown parser
renderer = Redcarpet::Render::HTML.new(options)
$markdown = Redcarpet::Markdown.new(renderer, extensions)

def lastdays(range)
    content = ""
    count = 0;
    text=File.open('reports.txt').read
    text.each_line do |line|
        if "#{line}".include? ("###")
            count += 1
        end
        if count >= range[0] && count <= range[1]
            content.concat("#{line}")
        end
        break if count == range[1]+1
    end
    temp = File.new('temp.txt', "w")
    temp.puts(content)
    temp.close
end

def checkConfig()
    $error = 0
    if ENV["DEFAULT_MESSENGER"].empty?
        puts "Default messenger must be filled !"
        $error = 1
    end
    if ENV["DEFAULT_MESSENGER"] == "hipchat" and (ENV["HIPCHAT_API_TOKEN"].empty? || ENV["HIPCHAT_ROOM"].empty?)
        puts "You need to fill your hipchat config details."
        $error = 1
    end
    if ENV["DEFAULT_MESSENGER"] == "slack" and ENV["SLACK_WEBHOOK"].empty?
        puts "You need to fill your slack webhook url."
        $error = 1
    end
    if $error != 0
        puts "Launch : dotdave config"
        exit
    end
end

def createHtmlFile(messenger = nil)
    file = File.new("reports.html", "w")
    if messenger == "hipchat"
        content = $markdown.render(File.read("temp.txt"))
    else
        content = "<!DOCTYPE html>\n<html>\n<head>\n<meta charset='UTF-8'>\n<title>dotdave - My daily's report</title>\n</head>\n<body>\n"
        content += $markdown.render(File.read("temp.txt"))
        content += "\n</body>\n</html>"
    end
    file.write(content)
    file.close
end

def sendHipchat()
    data = File.read("reports.html")
    filtered_data = data.gsub("<h3>", "<strong>").gsub("</h3>", "</strong>")
    File.open("reports.html", "w") do |f|
      f.write(filtered_data)
    end
	client = HipChat::Client.new(ENV["HIPCHAT_API_TOKEN"], :api_version => 'v2')
	client[ENV["HIPCHAT_ROOM"]].send('dotdave', File.read("reports.html"), :message_format => 'html')
end

def sendSlack()
    Slacked.post File.read("temp.txt")
end