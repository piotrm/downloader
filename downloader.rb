require 'net/http'
require 'nokogiri'
require 'uri'

class Downloader
  attr_accessor :main_url, :login, :password
  
  def initialize(main_url, login, password)
    @main_url = main_url
    @login = login
    @password = password
    @count = 0
  end
  
  def start_downloading
    links = []
    response = fetch(@main_url)
    links = get_links(response)
    recursive_download(links, @main_url)
    puts "Downloaded #{@count} files"
  end
  
private
  def recursive_download(links, parent_url)
    links.each do |link|
      #needed to ensure that urls with square brackets are accepted
      link.sub!(/\[/,'%5B')
      link.sub!(/\]/,'%5D')

      if link =~ /^.+\..{1,4}$/
        @count += 1
        puts "Downloading: #{link} (#{@count})"
        url = parent_url + link
        response = fetch(url)
        download(parent_url,link, response)
      else
        url = parent_url + link
        response = fetch(url)
        child_links = get_links(response)
        puts "--> Going inside #{link}"
        recursive_download(child_links, url)
        puts "<-- Leaving #{link}"
      end
    end
  end
  
  #fetching page content
  def fetch(url)
    req = Net::HTTP::Get.new(url.path)
    res = Net::HTTP.start(url.host, url.port) do |http|
      req.basic_auth "#{@login}", "#{@password}"
      http.request(req)
    end
    res
  end

  #get links from page
  def get_links(res)
    site_html = res.body.force_encoding("UTF-8")
    doc = Nokogiri::HTML::DocumentFragment.parse(site_html)
    links = []
    doc.xpath(".//a").each{|n| links.push(n['href'])}
    links.delete('../')
    
    links.each do |link|
      link = @main_url + link
    end
    links
  end

  #download file from particular link
  def download(parent_url, link, response)
    directory_name = parent_url.path.to_s[1..-1]
    download_directory = Dir::pwd + "/" + directory_name
    #puts "Download dir: #{download_directory}"
    directory_array = directory_name.split("/")
    
    #ensure directory hierarchy
    directory_array.each do |dir|
      index = directory_array.find_index(dir)
      temporary_directory = directory_array[0..index].join("/")
      unless FileTest::directory?(temporary_directory)
        Dir::mkdir(temporary_directory  )
      end
    end
    
    open(download_directory+"/"+link,"wb") do |file|
      file.write(response.body)
    end
  end
  
end