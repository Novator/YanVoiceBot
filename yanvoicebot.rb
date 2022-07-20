#!/usr/bin/env ruby
# encoding: UTF-8
# coding: UTF-8

# Telegram bot for speech recognition by Yandex SpeechKit
# RU: Телеграм бот для распознавания речи посредством Yandex SpeechKit
#
# The demonstration program is distributed under GNU GPLv2 licence
# RU: Демонстрационная программа распространяется под GNU GPLv2
#
# 2022 (c) robux

require 'telegram/bot'
require 'net/http'

BasicSocket.do_not_reverse_lookup = true
Thread.abort_on_exception = true

# Current directory
$bot_app_dir = Dir.pwd
# Files dir
$bot_files_dir = File.join($bot_app_dir, 'files')
# Log file
$bot_log_file = File.join($bot_files_dir, 'yanvoicebot.log')
# Telegram bot token file
$bot_token_file = File.join($bot_app_dir, 'token.txt')

#token = '54??????43:AA?????????????HZkRvUE?????????nvI8'
token = IO.read($bot_token_file).strip


$log_file = nil
$log_mutex = Mutex.new
$uri_parser = URI::Parser.new

$processing = true

LM_Error    = 0
LM_Warning  = 1
LM_Info     = 2
LM_Trace    = 3

# Default log level
# RU: Уровень логирования по умолчанию
Show_log_level = LM_Trace

# Log level on human view
# RU: Уровень логирования по-человечьи
def level_to_str(level)
  mes = ''
  case level
    when LM_Error
      mes = 'Error'
    when LM_Warning
      mes = 'Warning'
    when LM_Trace
      mes = 'Trace'
  end
  mes
end

# Add the message to log
# RU: Добавить сообщение в лог
def log_message(level, mes)
  if (level <= Show_log_level) and $log_mutex
    #$window.add_mes_to_log_view(mes, time, level)
    $log_mutex.synchronize do
      if $log_file.nil?
        begin
          $log_file = File.open($bot_log_file, 'a')
        rescue
          $log_file = nil
        end
        $log_file = false if $log_file.nil?
      end
      time = Time.now
      lev = level_to_str(level)
      lev = ' ['+lev+']' if lev.is_a?(String) and (lev.size>0)
      lev ||= ''
      mes = time.strftime('%Y.%m.%d %H:%M:%S') + lev + ': '+mes
      $log_file.puts(mes) if $log_file
      puts 'log: '+mes
    end
  end
end

# Fix URL special symbols
def fix_url(url)
  res = url.gsub(/[\[\]]/) { '%%%s' % $&.ord.to_s(16) }
end

# Get HTTP/HTTPS response object
# RU: Взять объект ответа HTTP/HTTPS
def get_http_response(url, limit = 10)
  res = nil
  raise(ArgumentError, 'HTTP redirect too deep ('+limit.to_s+')') if limit<=0
  url = $uri_parser.escape(url)  #unless url.ascii_only?
  uri = URI.parse(fix_url(url))
  options_mask = OpenSSL::SSL::OP_NO_SSLv2 + OpenSSL::SSL::OP_NO_SSLv3 +
    OpenSSL::SSL::OP_NO_COMPRESSION
  http = Net::HTTP.new(uri.host, uri.port)
  req = Net::HTTP::Get.new(uri.request_uri)
  if uri.scheme == 'https'
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.ssl_version = :SSLv23
  end
  response = http.request(req)
  case response
    when Net::HTTPSuccess
      res = response
    when Net::HTTPRedirection
      new_link = response['location']
      new_link = $uri_parser.unescape(new_link)
      puts('Redirect: '+new_link)
      res = get_http_response(new_link, limit - 1) if $processing
    else
      res = response.error!
  end
  res
end

# Start telegram thread
telegram_thread = Thread.new do
  prev_err_mes = nil
  puts('TelegramBot thread is started.')
  while $processing
    begin
      Telegram::Bot::Client.run(token) do |bot|
        bot.listen do |message|
          show_help = false
          case message
            when Telegram::Bot::Types::Message
              user_id = message.from.id
              chat_id = message.chat.id
              first_name = message.from.first_name
              last_name = message.from.last_name
              nick = message.from.username
              mes = message.text
              voice = nil
              if message.voice
                voice = message.voice
                if (voice.duration>0) and (voice.duration<=30)
                  if voice.mime_type=='audio/ogg'
                    #p ['***VOICE*** [voice, duration, file_id, file_unique_id, file_size]=', \
                    #  voice, voice.duration, voice.file_id, voice.file_unique_id, voice.file_size]
                    bot.api.send_message(chat_id: chat_id, text: \
                      'Audio is received!')
                    res = bot.api.getFile(file_id: voice.file_id)
                    if res and res['ok']
                      afile = res['result']
                      #p afile
                      file_path = afile['file_path']
                      url = 'https://api.telegram.org/file/bot'+token+'/'+file_path
                      #p url
                      http_response = get_http_response(url)
                      if http_response and http_response.body
                        full_file_name = File.join($bot_files_dir, file_path.gsub('/', '_'))
                        #p full_file_name
                        File.open(full_file_name, 'wb') do |file|
                          file.write(http_response.body)
                          bot.api.send_message(chat_id: chat_id, text: \
                            'Audio is saved! (Yandex Speech will be connected later)')
                        end
                      else
                        bot.api.send_message(chat_id: chat_id, text: \
                          'Cannot download audio with HTTPS')
                      end
                    else
                      bot.api.send_message(chat_id: chat_id, text: \
                        'Error while getFile')
                    end
                  else
                    bot.api.send_message(chat_id: chat_id, text: \
                      'Mime type must be "audio/ogg" (your is '+voice.mime_type.to_s+')')
                  end
                else
                  bot.api.send_message(chat_id: chat_id, text: \
                   'Voice duration must me in (1-30) seconds')
                end
              end
              if mes and (mes.size>2)
                comm = nil
                tail = nil
                if mes[0]=='/'
                  i = mes.index(' ')
                  if i
                    comm = mes[0, i]
                    tail = mes[i+1..-1]
                  else
                    comm = mes
                  end
                end
                user = 'Message: user_id=' + user_id.to_s + '('
                user << first_name if first_name
                user << ' '+last_name if last_name
                user << ' @'+nick if nick
                user << ')'
                log_message(LM_Trace, user+' ['+mes+']')
                case comm
                  when '/about'
                    bot.api.send_message(chat_id: chat_id, text: 'The demo bot is designed for voice recognition by Yandex Speech')
                  when '/help'
                    bot.api.send_message(chat_id: chat_id, text: 'Just record speech (from 1 to 30 seconds) and it will be recognized')
                  else
                    show_help = true
                end
              elsif not voice
                show_help = true
              end
            else
              show_help = true
          end
          if show_help
            bot.api.send_message(chat_id: chat_id, text: \
              'Use commands: /about /help')
          end
        end
      end
    rescue => err
      err_mes = err.message
      if (err_mes and (prev_err_mes.nil? or (prev_err_mes != err_mes)))
        log_message(LM_Error, 'Fail while bot working'+' "'+err_mes+'"')
        prev_err_mes = err_mes
      else
        sleep(5)
      end
    end
  end
  puts('TelegramBot thread is stopped.')
end

sleep(0.3)

puts 'Press <Enter> to quit.'
str = gets()    # Stop script until <Enter> key will be not pressed
$processing = false

sleep(0.2)

telegram_thread.exit if telegram_thread.alive?


