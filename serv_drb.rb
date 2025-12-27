require 'drb'
require 'erb'
require 'open3'
require 'sqlite3'
require 'find'
require './codir'


class MyService
  def home
    "<h1>Home page</h1>"
    File.read("./public/page")
    # system("kill #{Process.pid}")
  end

  def books
    File.read("./public/books.html")
  end

  def contacts
    "<h1>Oure contacts!</h1>"
  end

  def aboutus
    "<h1>About us!</h1>"
  end
  def info
    File.read("./public/home.html")
  end
  def read_file(file, type)
    # используем модуль find
    # Путь к папке
    start_directory = '.'
    # Ищем файл во всех подпапках
    pattern = "#{start_directory}/**/#{file}"
    path_file = Dir.glob(pattern).join
    # Dir.glob(pattern).each do |file_path|
    #   puts "Найден файл: #{file_path}"
    # end
    # Dir.glob(pattern)


    # # поиск файла в текущуй директории системные вызовы
    # find_comm = "find . -type f -name #{file}"
    # fstdout, fstderr, fstatus = Open3.capture3(find_comm)
    # str = File.binread(fstdout.chomp)
    body = File.binread(path_file)
    p "#{path_file} = #{get_content_type(type)} "
    "HTTP/1.1 200 OK\r\nContent-Type: #{get_content_type(type)}\r\nContent-Length: #{body.size}\r\n\r\n#{body}"
  end

  def new_user(str)

    require 'base64'
    # получить str
    user = str.read
    # перекодировать строку
    # p code = user.unpack('U*').pack('U*')
    p code = Encode.encoding(user)
    # распарсить str в хэш
    p pars = parse(user)
    # открыть базу даных
    # db = SQLite3::Database.new("dev.sqlite3")
    # # занести даные
    # db.execute "INSERT INTO users(name, email, created_at, password, phone) VALUES ('#{pars["name"]}', '#{pars["email"]}', '#{Time.now}', '#{ Base64.encode64(pars["password"])}', '#{pars["phone"]}' );"
    # # закрыть базу данных
    # db.close
    # перенаправить на другой ресурс
    File.read("./public/page.html") 
  end

  def session(str)

    require 'base64'
    # получить str
    us = str.read
    # перекодировать строку
    code = us.unpack('U*').pack('U*')
    # распарсить str в хэш
    pars = parse(code)
    # открыть базу даных
    db = SQLite3::Database.new("dev.sqlite3")
    # занести даные
    @user = db.execute "SELECT * FROM users WHERE email='#{pars["email"]}';"
    us = @user.flatten
    @user_post = db.execute "SELECT * FROM posts WHERE user_id='#{us[0]}';"

    # закрыть базу данных
    db.close


    ERB.new(IO.read("./public/user.html.erb")).result(binding)
    
  end
  def users
    db = SQLite3::Database.new("dev.sqlite3")
    # занести даные
    @users = db.execute "SELECT * FROM users"
    # закрыть базу данных
    db.close
    ERB.new(IO.read("./public/users.html.erb")).result(binding)
  end
  def delete_user(id)
    
    # Подключение к базе данных
    db = SQLite3::Database.new("dev.sqlite3")
    
    # SQL-запрос
    sql_query = "DELETE FROM users WHERE id ='#{id.read.split("=")[1]}';"
    # Выполнение запроса
    db.execute(sql_query)

    # Закрытие соединения
    db.close()

    ERB.new(IO.read("./public/users.html.erb")).result(binding)
  end

  def new_post(str)

    # # получить str
    post = str.read
    # перекодировать строку
    code = post.unpack('U*').pack('U*')
    # распарсить str в хэш
    pars = parse(code)
    # открыть базу даных
    db = SQLite3::Database.new("dev.sqlite3")
    # занести даные
    db.execute "INSERT INTO posts(user_id, title, content, photo, created_at) VALUES ('#{pars["title"]}', '#{pars["content"]}', '#{pars["photo"]}', '#{Time.now}');"
    # закрыть базу данных
    db.close
    # перенаправить на другой ресурс
    # File.read("./public/new_post.html") 
    "<!DOCTYPE html><html><head><meta http-equiv=\"Refresh\" content=\"0; URL=home\"/><head><body></body></html>"   

  end

  def show_post
    
    db = SQLite3::Database.new("dev.sqlite3")
    # занести даные
    @posts = db.execute "SELECT * FROM posts"
    # закрыть базу данных
    db.close
    ERB.new(IO.read("./public/content.html.erb")).result(binding)
    
  end

  def show_tovar
    
    db = SQLite3::Database.new("dev.sqlite3")
    # занести даные
    @tovar = db.execute "SELECT * FROM tovar"
    # p @tovar
    # закрыть базу данных
    db.close
    ERB.new(IO.read("./public/tovar.html.erb")).result(binding)
    
  end

  private

  def parse(str)
    a = []
    str.gsub!("%40", "@")
    arr_str = str.split("&")
    for line in arr_str
      h = line.split("=")
      a << h
    end
    return a.to_h
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
      return "application/octet-stream"
    end

  end

  def authenticate(str)
    return str
  end

end

server = MyService.new
DRb.start_service('druby://:9000', server)
puts "Сервер запущен на druby://:9000"
DRb.thread.join

# system("kill #{Process.pid}")
