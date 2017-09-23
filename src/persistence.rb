require 'tadb'
require_relative './boolean.rb'

module Persistence

  def self.included base
    base.send :extend, ClassPersistence
    base.send :include, InstancePersistence
  end

  module ClassPersistence
    attr_accessor :persistable_fields, :many_persistable_fields
    def has_one type, hash
      @persistable_fields ||= []
      @persistable_fields << (define_persistable_field hash[:named], type)
    end

    def has_many type, hash
      @many_persistable_fields ||= []
      @many_persistable_fields << (define_persistable_field hash[:named], type)
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
      @persistable_fields.each.each { |field| instance.instance_variable_set("@#{field[:name]}", attributes[field[:name]]) }
      instance.instance_variable_set("@id", attributes[:id])
      instance
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
      value = self.instance_eval("#{field[:name]}")
      if is_a_primitive_type? value
        { field[:name] => value }
      else
        save_object_field field, value
      end
    end

    def save_object_field field, value
      if value.is_a? Array
        ## TODO terminar has_many
        value.each {|oneValue| oneValue.save!}
      end
      value.save!
      { field[:name] => value.id }
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
      if not is_a_primitive_type? actualValue
        actualValue.refresh!
      else
        self.instance_variable_set("@#{field[:name]}", value)
      end
    end

    def forget!
      @table.delete(@id)
      remove_instance_variable(:@id)
    end

  end
end