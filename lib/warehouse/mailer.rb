begin
  require 'mailfactory'
  require 'net/smtp'
rescue LoadError
  puts "You need to install the mailfactory gem to use Warehouse::Mailer"
end  

class MailFactory
  attr_reader :html, :text
end

# Copied this from Merb, thanks guys, you rock
module Warehouse
  # You'll need a simple config like this in merb_init.rb if you want
  # to actually send mail:
  #
  #   Warehouse::Mailer.config = {
  #     :host=>'smtp.yourserver.com',
  #     :port=>'25',              
  #     :user=>'user',
  #     :pass=>'pass',
  #     :auth=>:plain # :plain, :login, or :cram_md5, default :plain
  #   }
  #   Warehouse::Mailer.delivery_method = :sendmail
  #
  # You could send mail manually like this (but it's better to use
  # a MailController instead).
  # 
  #   m = Warehouse::Mailer.new :to => 'foo@bar.com',
  #                        :from => 'bar@foo.com',
  #                        :subject => 'Welcome to whatever!',
  #                        :body => partial(:sometemplate)
  #   m.deliver!                     

  class Mailer
    class << self
      attr_accessor :config
      attr_accessor :delivery_method
      attr_accessor :deliveries
    end

    attr_accessor :mail
    self.deliveries = []
    
    def sendmail
      sendmail = IO.popen("sendmail #{@mail.to}", 'w+')
      sendmail.puts @mail.to_s
      sendmail.close
    end
  
    # :plain, :login, or :cram_md5
    def net_smtp
      Net::SMTP.start(self.class.config[:host], self.class.config[:port].to_i, self.class.config[:domain], 
                      self.class.config[:user], self.class.config[:pass], (self.class.config[:auth].to_sym||:plain)) { |smtp|
        smtp.send_message(@mail.to_s, @mail.from.first, @mail.to)
      }
    end
    
    def test_send
      self.class.deliveries << @mail
    end
    
    def deliver!
      send(self.class.delivery_method || :net_smtp)
    end
      
    def attach(file_or_files, filename = file_or_files.is_a?(File) ? File.basename(file_or_files.path) : nil, 
      type = nil, headers = nil)
      if file_or_files.is_a?(Array)
        file_or_files.each {|k,v| @mail.add_attachment_as k, *v}
      else
        raise ArgumentError, "You did not pass in a file. Instead, you sent a #{file_or_files.class}" if !file_or_files.is_a?(File)
        @mail.add_attachment_as(file_or_files, filename, type, headers)
      end
    end
      
    def initialize(o={})
      self.class.config = :sendmail if self.class.config.nil?
      m = MailFactory.new()
      o.each { |k,v| m.send "#{k}=", v }
      @mail = m
    end
    
  end
end

Warehouse.setup_mail!
