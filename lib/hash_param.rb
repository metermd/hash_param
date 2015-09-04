require 'hash_param/version'

module HashParam
  def self.included(cls)
    cls.extend(ClassMethods)
  end

  module ClassMethods
    def hash_param(*method_names, transform_key: nil, from: nil)
      method_names.each do |method_name|
        visibility = instance_method_visibility(method_name)
        hidden_name = "#{method_name}_before_hash_param"

        alias_method hidden_name, method_name
        private hidden_name

        if from.nil?
          # We're passed the argument, e.g., caller expects f(data)
          define_method(method_name) do |arg|
            hash_param_dispatch(hidden_name, arg, transform_key: transform_key)
          end
        elsif from.is_a?(Symbol) && from.to_s[0] == '@'
          # Pull the data from an instance variable
          define_method(method_name) do
            hash_param_dispatch(hidden_name, instance_variable_get(from),
                                transform_key: transform_key)
          end
        elsif from.is_a?(Symbol)
          # Pull the Hash from a method, e.g., Rails' `params`
          define_method(method_name) do
            hash_param_dispatch(hidden_name, send(from),
                                transform_key: transform_key)
          end
        end

        # Set the new wrapping method's visibility to what the original was.
        send(visibility, method_name)
      end
    end

    private
    # This determines the visibility of an instance method, e.g.,
    # Object.instance_method_visibility(:object_id) => :public
    def instance_method_visibility(method_name)
      return :public    if public_instance_methods.include?(method_name)
      return :protected if protected_instance_methods.include?(method_name)
      return :private   if private_instance_methods.include?(method_name)
      fail NoMethodError, "Cannot access visibility of #{name}\##{method_name}"
    end
  end

  private
  def hash_param_dispatch(method_name, data, transform_key: nil)
    args, kwargs, rest_index, has_kwrest = [], {}, nil, nil
    public_method_name = method_name

    if transform_key
      data = data.map do |k, v|
        [k.to_s.send(transform_key), v]
      end.to_h
    end

    method(method_name).parameters.each.with_index do |(type, name), i|
      # attempt symbol
      key_name = name
      exists = data.key?(key_name)

      # try again with string key
      if !exists
        key_name = name.to_s
        exists = data.key?(key_name)
      end

      value = data.delete(key_name)

      case type
        when :req
          fail ArgumentError, "#{public_method_name}: required argument " +
                              "`#{name}' not present" unless exists
          args.push(value)

        when :opt
          args.push(value) if exists

        when :keyreq
          fail ArgumentError, "#{public_method_name}: required keyword argument " +
                              "`#{name}' not present" unless exists
          kwargs[name] = value

        when :key
          kwargs[name] = value if exists

        when :rest
          # If data happens to contain a key with the same name as the rest arg,
          # we still want it to show up string-ized, so we put back the value
          # we deleted earlier.
          data[key_name] = value if exists
          rest_index = i

        when :keyrest
          # Because keyrest supercedes rest, we add this to kwargs if the
          # data hash happened to contain a key named the same as the keyrest
          # argument name.
          kwargs[name] = value if exists
          has_kwrest = true

        else
          fail ArgumentError, "#{public_method_name}: cannot dispatch " +
                              "argument `#{name}', (type: #{type}) from Hash"
      end
    end

    if has_kwrest
      kwargs.merge!(data.map { |k,v| [k.to_sym, v] }.to_h)
    elsif rest_index
      args[rest_index, 0] = data unless data.empty?
    end

    if kwargs.empty?
      send(method_name, *args)
    else
      send(method_name, *args, **kwargs)
    end
  end
end
