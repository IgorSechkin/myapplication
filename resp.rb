require 'erb'
require 'socket'
require 'stringio'

Type_struct = Struct.new("Types", :document, :style, :image, :audio, :video, :manifest, :script, :empty)

class Response 
  
  attr_accessor :body, :type, :sock

  def initialize(envir)
    @path_info = envir["REQUEST_PATH"]
    @env_type = envir["HTTP_SEC_FETCH_DEST"]
    @sock = envir["puma.socket"]
    @mutex = Thread::Mutex.new
    @type = Type_struct.new("text/html", "text/css", "image/gif", "text/css", "text/css", "application/json", "text/javascript", "application/xml; charset=utf-8")
    
  end
  
  def send_data
      get_body_str{ |f|
        if @path_info =~ /\D+\.(?:png|css|jpeg|jpg|avi|mp4|xml|mp3|xml|js|ico|json|txt)/
            file = File.binread("public" + @path_info)
            str = "HTTP/1.1 200 OK\r\nContent-Type: #{@type[@env_type]}\r\nContent-Length: #{file.size}\r\n\r\n#{file}"
            @sock.write str
        elsif @path_info =~ /\D+\.(?:php)/
            file = File.binread("public" + @path_info)
            # str = "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Length: #{file.size}\r\n\r\n#{file}"
            str = system("php ./public#{@path_info}")
            @sock.write str
        elsif @path_info =~ /([^=]+)=([^;]+)/
            "HTTP/1.1 200 OK\r\nContent-Type: text/css\r\nSet-Cookie: #{@path_info}; HttpOnly; secure; SameSite=Lax;\r\nContent-Length: #{@path_info.size}\r\n\r\n#{@path_info}"
        elsif @path_info == "/"
            f = File.binread("public/index.html")
        elsif @path_info =~ /\D+\.(?:html)/
            f = File.binread("public"+@path_info)
        else
        end

      }

  end

  private

  def get_body_str
    @mutex.synchronize do
      @body = nil
      @body = ERB.new(IO.read('template.html.erb')).result(binding)
      # @str = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: #{@body.size}\r\n\r\n#{@body}"
      return @body
    end
    # @sock.write @str
  end

end

