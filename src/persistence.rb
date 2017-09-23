require 'tadb'
require_relative './boolean.rb'

module Persistence

  def self.included base
    base.extend ClassPersistence
    base.include InstancePersistence
  end

  module ClassPersistence
    attr_accessor :persistable_fields

    def has_one type, hash
      @persistable_fields ||= []
      @persistable_fields << (define_persistable_field hash[:named], type)
    end

    def has_many type, hash
      has_one type, hash
    end

    def define_persistable_field name, type
      attr_accessor(name)
      persistable_field = {name: name, type: type}
      persistable_field
    end

    def all_instances
      instances = []
      table = TADB::DB.table(self.name)
      table.entries.each { |instance| instances << (self.createNewInstance instance) }
      instances
    end

    def createNewInstance attributes
      instance = self.new
      @persistable_fields.each { |field| initializeByType instance, field[:name], field[:type], attributes[field[:name]] }
      instance.instance_variable_set("@id", attributes[:id])
      instance
    end

    def initializeByType instance, name, type, value
      if is_a_primitive_type? type.to_s
        instance.instance_variable_set("@#{name}", value)
      else
        has_one_instance = type.find_by_id(value).first
        instance.instance_variable_set("@#{name}", has_one_instance)
      end
    end

    def is_a_primitive_type? type
      type == "String" or type == "Boolean" or type == "Numeric"
    end

    def method_missing(sym, *args, &block)
      method = sym.to_s
      if method.start_with? 'find_by'
        instance_method = method[8..-1]
        find_by instance_method, args[0]
      else
        super(sym, *args, &block)
      end
    end

    private

    def find_by instance_method, arg
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

    def save!
      hash = {}
      self.class.persistable_fields.each { |field| hash.merge!(save_field field) }
      id = table.insert(hash)
      @id = id
    end

    def save_field field
      value = self.instance_variable_get("@#{field[:name]}")
      if is_a_primitive_type? value
        { field[:name] => value }
      else if value.is_a? Array
            create_hash_for_many field[:name], value
           else
             value.save!
             { field[:name] => value.id }
           end
      end
    end

    def create_hash_for_many name, list
      table_name = self.class.name + "_" + name.to_s
      many_table = TADB::DB.table(table_name)
      ids = []
      list.each { |object| ids << (object.save!) }
      ids.each {|id| many_table.insert(key_for_many id)}
      {name => table_name}
    end

    def key_for_many id
      {"foreign_key" => id}
    end

    def is_a_primitive_type? value
      value.is_a? String or value.is_a? Numeric or value.is_a? Boolean
    end

    def refresh!
      if @id
        instance = @table.entries.find{ |i| i[:id] == @id }
        self.class.persistable_fields.each { |field| refresh_field field, instance}
      else
        raise("Este objeto no tiene id!")
      end
    end

    def refresh_field field, instance
      value = instance[field[:name]]
      actualValue =  self.instance_variable_get("@#{field[:name]}")
      if is_a_primitive_type? actualValue
        self.instance_variable_set("@#{field[:name]}", value)
      else if actualValue.is_a? Array
             actualValue.each {|obj| obj.refresh!}
           else
             actualValue.refresh!
           end
      end
    end

    def forget!
      @table.delete(@id)
      remove_instance_variable(:@id)
    end

  end
end