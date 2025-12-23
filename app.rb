require 'erb'
require 'open3'
require './resp'
# require './serv_drb'


class App
  attr_accessor :body, :env_type, :sock, :path_info, :type

  def initialize()

    @mutex = Thread::Mutex.new
    @type = Type_struct.new("text/html", "text/css", "image/gif", "text/css", "text/css", "application/json", "text/javascript", "application/octet-stream")
    
  end

  def call(env)
    # DRb.start_service
    # ro = DRbObject.new_with_uri("druby://localhost:9000")
    # p "params = #{env["rack.input"].read}"
    # env.each{|en| p en}
    @path_info = env["REQUEST_PATH"]
    @env_type = env["HTTP_SEC_FETCH_DEST"]
    @sock = env["puma.socket"]
    # resp = Response.new(env)
    # # p resp.send_data
    # [200, {"content-type" => "text/html"}, [resp.send_data] ]
    # p @type[@env_type]
    # p get_template{get_block_template(@path_info)}
    # p get_content_type(@env_type)
    # [200, {"content-type" => "#{@type[@env_type]}"}, [get_template{get_block_template(@path_info)}] ]
    [200, {"content-type" => "#{get_content_type(@env_type)}"}, [get_template{get_block_template(@path_info)}] ]
  end

  private

  def get_template
    return ERB.new(IO.read('template.html.erb')).result(binding) if block_given?
  end

  def get_block_template(arg)
    file = arg.delete("/") if arg != nil
    if file != "" && file != nil
      # поиск файла в текущуй директории
      find_comm = "find . -type f -name #{file}"
      # find_comm = "find . -name #{file}"
      fstdout, fstderr, fstatus = Open3.capture3(find_comm)
    end
    p file
    if fstdout =~ /\D+\.(?:png|jpeg|jpg|avi|mp4|xml|mp3|ico|css|xml|js|json|txt)/
      file = File.binread(fstdout.chomp)
      str = "HTTP/1.1 200 OK\r\nContent-Type: #{get_content_type(@env_type)}\r\nContent-Length: #{file.size}\r\n\r\n#{file}"
      @sock.write str
    # elsif fstdout =~ /\D+\.(?:css|xml|js|json|php|txt)/
    #   file = File.binread(fstdout.chomp)
    #   file.unpack("U*").pack("C*")
    elsif fstdout =~ /\D+\.(?:php)/
      # file = File.binread(fstdout.chomp)
      # str = "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Length: #{file.size}\r\n\r\n#{file}"
      str = system("php .#{fstdout.chomp}")
      # @sock.write str
    elsif @path_info == "/"
      File.binread("public/index.html")
    elsif fstdout =~ /\D+\.(?:html)/
      File.binread(fstdout.chomp)
    # elsif fstdout == "home" || fstdout == "show_post" ||  fstdout == "aboutus" ||  fstdout == "info" || fstdout == "new_post" ||
    #         fstdout == "contacts" || fstdout == "page" || fstdout == "users" || fstdout == "session" || fstdout == "show_tovar" # нужно что-то придумать что-бы пропускало только указатель на ресурс 
    #     if env["REQUEST_METHOD"] == "POST"
    #       ERB.new(ro.send(fstdout, env["rack.input"])).result(binding) 
    #     else
    #       ERB.new(ro.send(fstdout)).result(binding) 
    #     end
    elsif fstdout =~ /([^=]+)=([^;]+)/
      "HTTP/1.1 200 OK\r\nContent-Type: text/css\r\nSet-Cookie: #{arg}; HttpOnly; secure; SameSite=Lax;\r\nContent-Length: #{arg.size}\r\n\r\n#{arg}"
    else

    end

  end

  def get_content_type(arg)
    if arg == "document"
      return "text/html"
    elsif arg == "style"
      return "text/css"
    elsif arg == "image"
      return "image/gif"
    elsif arg == "audio"
      return "audio/mpeg"
    elsif arg == "video"
      return "video/mp4"
    elsif arg == "manifest"
      return "application/json"
    elsif arg == "script"
      return "text/javascript"
    elsif arg == "empty"
      return "application/xml; charset=utf-8"
    else
      return "text/html"
    end

  end

end