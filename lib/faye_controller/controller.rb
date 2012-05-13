# {http://faye.jcoglan.com/ Faye}  module extend with controller class
module Faye
  # Base class for create rails like controller based on faye channel. By default controller subscribe to one channel. Name of this channel is the
  # class name (downcase and underscore)
  #
  #   "CustomersController" # => "/customer"
  #   "Public::CustomersController" # => "/public_customer"
  #
  # Default channel name can be changed with method {channel}
  #
  # To create controllers instances and subscribe to channels call class method {init}
  class Controller
    # Initialize all controllers
    # @param [Object] faye faye client instance
    # @example Initialize controllers
    #   @client = Faye::Client.new('http://localhost:9000/faye')
    #   Faye::Controller.init @client
    def self.init fayer
      self.controllers.delete_if { |controller| controller.new fayer }
    end

    # Change default channel name
    # @note This method can be used not only to set channel name, but to get channel name too (call without parameter name)
    # @param [String] name channel name
    # @return [String] channel name
    # @example Change default channel name
    #   class CustomersController
    #     channel '/server/customers'
    #   end
    def self.channel name = nil
      @channel ||= name
    end

    def initialize fayer
      @fayer = fayer
      @fayer.subscribe channel do |message| dispatch message end
    end

    protected

    def channel
      unless defined? @channel
        @channel = self.class.channel || "/#{underscore demodulize self.class.to_s.gsub(/controller$/i, '')}"
      end
      @channel
    end

    def dispatch message
      message.deep_symbolize_keys!
      return unless message[:action]

      @action = message[:action].to_sym
      if self.respond_to? @action
        @params = message[:params]
        self.send @action
      end
    end

    def params
      @params ||= {}
    end

    private

    def demodulize(class_name_in_module)
      class_name_in_module.to_s.gsub(/^.*::/, '')
    end

    def underscore(camel_cased_word)
      word = camel_cased_word.to_s.dup
      word.gsub!(/::/, '/')
      word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end

    def respond channel, action, params = nil
      @fayer.publish channel, :action => action, :params => params
    end

    private

    def self.controllers
      @controllers ||= []
    end

    def self.inherited(controller)
      self.controllers << controller
    end

  end
end