require 'tadb'
require_relative './boolean.rb'

module Persistence

  def self.included (base)
    base.extend ClassPersistence
    base.include InstancePersistence
  end

  module ClassPersistence
    attr_accessor :sticky_fields, :sticky_validations

    def descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    def new
      instance = super
      @sticky_fields ||= {}
      set_default_for_instance instance
      instance
    end

    def set_default_for_instance (instance)
      @sticky_fields.each do
      |name, type|
        if @sticky_validations[name][:default]
          instance.instance_variable_set("@#{name}", @sticky_validations[name][:default])
        end
      end
    end

    def has_one (type, hash)
      @sticky_fields ||= {}
      @sticky_validations ||= {}
      if superclass_is_sticky?
        define_sticky_superclass
      end
      included_modules.each {|oneModule| define_module_sticky_fields oneModule}
      define_sticky_field hash[:named]
      @sticky_fields[hash[:named]] = type
      @sticky_validations[hash[:named]] = hash.reject!{ |k| k == :named }
    end

    def superclass_is_sticky?
      self.respond_to? "superclass" and self.superclass.instance_variable_get(:@sticky_fields)
    end

    def define_sticky_superclass
      superclass.instance_variable_get(:@sticky_fields).each do
      |name, type| @sticky_fields[name] = type
      end
      superclass.instance_variable_get(:@sticky_validations).each do
      |name, validations| @sticky_validations[name] = validations
      end
    end

    def define_module_sticky_fields (oneModule)
      if oneModule.respond_to? "sticky_fields"
        oneModule.sticky_fields.each do
        |name, type| @sticky_fields[name] = type
        end
      end
    end


    def has_many (type, hash)
      has_one type, hash
    end

    def define_sticky_field (name)
      attr_accessor(name)
    end

    def all_instances
      table = TADB::DB.table(self.name)
      instances = table.entries.flat_map { |instance|  (create_new_instance instance) }
      descendants.each { |descendant| instances.concat(descendant.all_instances) }
      instances
    end

    def create_new_instance (attributes)
      instance = self.new
      @sticky_fields.each do
      |name, type| initialize_by_type instance, name, type, attributes
      end
      instance.instance_variable_set("@id", attributes[:id])
      instance
    end

    ## Abstract logic with the last 3 methods?
    ## The logic is: if is a primitive type, else if a has_many, else

    def initialize_by_type (instance, name, type, attributes)
      value = attributes[name]
      if is_a_primitive_type? (type.to_s)
        instance.instance_variable_set("@#{name}", value)
      else if value.is_a? String and value.start_with? self.name
             initialize_has_many value, instance, name, type, attributes
           else
             has_one_instance = type.find_by_id(value).first
             instance.instance_variable_set("@#{name}", has_one_instance)
           end
      end
    end

    def initialize_has_many (value, instance, name, type, attributes)
      many_table = TADB::DB.table(value)
      has_many_instances = many_table.entries().select {|entry| entry[:self_id] == attributes[:id]}
      real_instances = []
      has_many_instances.each {|instance| real_instances << (type.find_by_id(instance[:foreign_key]).first)}
      instance.instance_variable_set("@#{name}", real_instances)
    end

    def is_a_primitive_type? (type)
      type == "String" or type == "Boolean" or type == "Numeric"
    end

    def method_missing(sym, *args, &block)
      method = sym.to_s
      if method.start_with? 'find_by'
        instance_method = get_method_name method
        find_by instance_method, args[0]
      else
        super(sym, *args, &block)
      end
    end

    def get_method_name (method)
      method[8..-1]
    end

    def find_by (instance_method, arg)
      if self.method_defined? instance_method and self.instance_method(instance_method).arity == 0
        self.all_instances.select {|instance| instance.send(instance_method) == arg}
      else
        raise("El metodo no existe o tiene parametros")
      end
    end

  end

  module InstancePersistence
    attr_accessor :table, :id

    def initialize
      @table = TADB::DB.table(self.class.name)
      @id = nil
    end

    def sticky_fields
      self.class.sticky_fields
    end

    def sticky_validations
      self.class.sticky_validations
    end

    def save!
      validate!
      hash = {}
      sticky_fields.each do
      |name, type| hash.merge!(save_field name)
      end
      id = table.insert(hash)
      save_has_many_fields id
      @id = id
    end

    def save_has_many_fields (id)
      sticky_fields.select { |name, type| self.instance_variable_get("@#{name}").is_a? Array }
          .each do  |name, type| create_hash_for_many name, id
      end
    end

    def create_hash_for_many (name, selfId)
      list = self.instance_variable_get("@#{name}")
      table_name = self.class.name + "_" + name.to_s
      many_table = TADB::DB.table(table_name)
      ids = []
      list.each { |object| ids << (object.save!) }
      ids.each {|id| many_table.insert(key_for_many id, selfId)}
    end

    def key_for_many (id, selfId)
      {"foreign_key" => id, "self_id" => selfId}
    end

    def is_a_primitive_type? (value)
      value.is_a? String or value.is_a? Numeric or value.is_a? Boolean
    end

    def refresh!
      if @id
        instance = @table.entries.find{ |i| i[:id] == @id }
        sticky_fields.each do
        |name, type| refresh_field name, instance
        end
      else
        raise("Este objeto no tiene id!")
      end
    end

    def validate!
      sticky_fields.each do
      |name, type| validate_field(name, type)
      end
    end

    ## This 3 methods could abstract logic?
    ## Duplicated logic: if is a primitive type, else if is an array, else
    ## How could this be abstracted?

    def save_field (name)
      hash = {}
      value = self.instance_variable_get("@#{name}")
      unless value == nil
        if is_a_primitive_type? value
          hash[name] = value
        else if value.is_a? Array
               hash[name] = self.class.name + "_" + name.to_s
             else
               value.save!
               hash[name] =  value.id
             end
        end
      end
      hash
    end

    def refresh_field (name, instance)
      value = instance[name]
      actualValue =  self.instance_variable_get("@#{name}")
      if is_a_primitive_type? actualValue
        self.instance_variable_set("@#{name}", value)
      else if actualValue.is_a? Array
             actualValue.each {|obj| obj.refresh!}
           else
             actualValue.refresh!
           end
      end
    end

    ## This is a complicated method

    def validate_field (name, type)
      value = self.instance_variable_get("@#{name}")
      unless value == nil
        if self.is_a_primitive_type? value
          sticky_validations[name].each do
          |valid_name, validation| send(valid_name, value, validation, name)
          end
          unless value.is_a? type
            raise("Error de tipos")
          end
        else
          if value.is_a? Array
            value.each {|obj| obj.validate!}
          else
            sticky_validations[name].each do
              |valid_name, validation| value.send(valid_name, value, validation, name)
            end
            value.validate!
          end
        end
      else
        send("default", value, sticky_validations[name][:default], name)
      end
    end

    def forget!
      @table.delete(@id)
      remove_instance_variable(:@id)
    end

    def no_blank (value, validation, name)
      if value.is_a? Boolean and validation == true
        if value == nil or value == ""
          raise("Error de tipos")
        end
      end
    end

    def validate (value, proc, name)
      unless self.instance_eval(&proc)
        raise("Error de tipos")
      end
    end

    ## Abstract to and from
    def from (value, validation, name)
      if value.is_a? Numeric
        if value < validation
          raise("Error de tipos")
        end
      end
    end

    def default (value, validation, name)
      if value == nil
        self.instance_variable_set("@#{name}", validation)
      end
    end

    def to (value, validation, name)
      if value.is_a? Numeric
        if value > validation
          raise("Error de tipos")
        end
      end
    end
  end
end