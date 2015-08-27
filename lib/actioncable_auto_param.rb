require 'actioncable_auto_param/version'
require 'action_cable/channel'

module ActioncableAutoParam
  module ClassMethods
    def auto_param(*method_names)
      method_names.each do |method_name|
        if method_name == :all
          self.auto_param_all_methods = true
        end

        self.auto_param_methods ||= []
        self.auto_param_methods.push(method_name)
      end
    end

    def auto_param?(method_name)
      auto_param_all_methods || (auto_param_methods || []).include?(method_name)
    end
  end

  def self.prepended(cls)
    cls.class_attribute :auto_param_all_methods
    cls.class_attribute :auto_param_methods
  end

  # Monkeypatch
  def dispatch_action(action, data)
    method_name = action.to_sym
    if self.class.auto_param?(method_name)
      auto_param_dispatch(method_name, data)
    else
      super
    end
  rescue
    puts $!, $!.backtrace
  end

  private
  def auto_param_dispatch(method_name, data)
    args, kwargs, rest_index, has_kwrest = [], {}, nil, nil

    method(method_name).parameters.each.with_index do |(type, name), i|
      key_name = name.to_s
      exists = data.key?(key_name)
      value = exists ? data.delete(key_name) : nil

      case type
        when :req
          fail ArgumentError, "#{method_name}: required argument " +
                              "`#{name}' not present" unless exists
          args.push(value)

        when :opt
          args.push(value) if exists

        when :keyreq
          fail ArgumentError, "#{method_name}: required keyword argument " +
                              "`#{name}' not present" unless exists
          kwargs[name] = value

        when :key
          kwargs[name] = value if exists

        when :rest
          rest_index = i

        when :keyrest
          has_kwrest = true

        else
          fail ArgumentError, "#{method_name}: cannot dispatch argument `#{name}', " +
                              "(type: #{type}) from Hash"
      end
    end

    if has_kwrest
      kwargs.merge!(data.map { |k,v| [k.to_sym, v] }.to_h)
    elsif rest_index
      args[rest_index, 0] = data
    end

    if kwargs.empty?
      send(method_name, *args)
    else
      send(method_name, *args, **kwargs)
    end
  end
end

ActionCable::Channel::Base.extend(ActioncableAutoParam::ClassMethods)
ActionCable::Channel::Base.prepend(ActioncableAutoParam)
