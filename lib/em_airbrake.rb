require 'ostruct'
require 'eventmachine'
require 'em-http'
require 'em_airbrake/version'
require 'builder'

module EmAirbrake
  ENDPOINT = 'http://airbrake.io/notifier_api/v2/notices'.freeze
  BACKTRACE_EXP = %r{^([^:]+):(\d+)(?::in `([^']+)')?$}.freeze
  API_VERSION = '2.0'.freeze
  GEM_HOME = 'http://github.com/ismasan/em_airbrake'.freeze
  
  attr_reader :config

  def configure(&block)
    @config = OpenStruct.new
    block.call @config
    check_config!
  end
  
  def notify(args = {})
    error = args.delete(:error)
    backtrace = error.respond_to?(:backtrace) ? error.backtrace : nil
    default_url = args.delete(:url) || 'default'
    
    data = {
      :error_class   => error.class.name,
      :parameters    => {},
      :api_key       => config.api_key,
      :error_message => "#{error.class.name}:#{error.respond_to?(:message) ? error.message : ''}",
      :backtrace     => backtrace,
      :parameters    => {},
      :session       => {},
      :url           => default_url,
      :component     => default_url,
      :env           => nil
    }.merge(args)
    
    post(data)
  end
  
  protected
  
  def check_config!
    raise ArgumentError, "you need config.api_key" unless config.api_key
  end
  
  def post(data)
    @req = EM::HttpRequest.new(ENDPOINT).post(
      :head => {'Content-Type' => 'text/xml', 'Accept' => 'text/xml, application/xml', 'User-Agent'=>'Ruby'},
      :body => xml(data)
    )
    @req.callback {
      p [:req, @req.response_header.status, @req.response]
    }
    @req
  end
  
  def xml_vars_for(builder, hash)
    hash.each do |key, value|
      if value.respond_to?(:to_hash)
        builder.var(:key => key.to_s){|b| xml_vars_for(b, value.to_hash) }
      else
        v = value.is_a?(String) ? value : value.inspect
        builder.var(v, :key => key.to_s)
      end
    end
  end
  
  def xml(data)
    builder = Builder::XmlMarkup.new
    builder.instruct!
    xml = builder.notice(:version => API_VERSION) do |notice|
      # API KEY ===================
      notice.tag!("api-key", config.api_key)
      # NOTIFIER ===================
      notice.notifier do |notifier|
        notifier.name('EmAirbrake')
        notifier.version(EmAirbrake::VERSION)
        notifier.url(GEM_HOME)
      end
      notice.error do |error|
        error.tag!('class', data[:error_class])
        error.message(data[:error_message])
        
        # BACKTRACE ===================
        if data[:backtrace]
          error.backtrace do |backtrace|
            
            data[:backtrace].each do |line|
              _, file, number, method = line.match(BACKTRACE_EXP).to_a
              backtrace.line(:number => number,
                             :file   => file,
                             :method => method)
            end
          end
        end
        
      end
      
      # REQUEST ==================
      notice.request do |request|
        # Required
        request.url(data[:url])
        # Required
        request.component(data[:component])
        # PARAMS ===================
        if data[:parameters]
          request.params do |params|
            xml_vars_for(params, data[:parameters])
          end
        end
        
        # Environment ===============
        if data[:env]
          request.tag!('cgi-data') do |cgi|
            xml_vars_for(cgi, data[:env])
          end
        end
        
      end
      
      # SERVER ENV
      notice.tag!("server-environment") do |env|
        env.tag!("project-root", ::File.dirname($0))
        env.tag!("environment-name", environment_name)
        env.tag!("hostname", `hostname`.chomp)
      end
      
    end
    xml.to_s
  end
  
  def environment_name
    ENV['RACK_ENV'] || ENV['RAILS_ENV'] || ENV['ENVIRONMENT'] || 'development'
  end
  
  extend self
end
