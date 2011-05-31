require './downloader'

url = URI.parse()
login = 
password = 

dl = Downloader.new(url, login, password)
dl.start_downloading