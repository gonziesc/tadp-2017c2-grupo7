require 'tadb'
require_relative './boolean.rb'

module Persistence

  def self.included (base)
    base.extend ClassPersistence
    base.include InstancePersistence
  end

  module ClassPersistence
    attr_accessor :sticky_fields, :table
    def sticky_fields
      @sticky_fields ||= []
    end

    def table
      @table ||= TADB::DB.table(name)
    end

    def has_one (type, named:)
      primitive?(type) ? sticky_fields << SimpleField.new(type, named) : sticky_fields << ComplexField.new(type, named)
      attr_accessor(named)
    end

    def save!(instance)
      instance.id = table.upsert(instance.to_hash)
    end

    def forget!(instance)
      table.delete(instance.id)
      instance.id = nil
    end

    def refresh!(instance)
      sticky_fields.each {|field| (field.refresh!(instance)) }
    end

    def to_hash(instance)
      hash = {}
      sticky_fields.each {|field| hash.merge! (field.save!(instance)) }
      hash
    end

    def all_instances
      table = TADB::DB.table(self.name)
      instances = table.entries.flat_map { |instance| (create_new_instance instance) }
      instances
    end

    def create_new_instance (attributes)
      instance = self.new
      sticky_fields.each {|field| field.assign(instance, attributes[field.name])}
      instance.id = attributes[:id]
      instance
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

    def getFromDB(instance)
      table.entries.find{ |i| i[:id] == instance.id }
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

    def primitive?(type)
      (type == String) || (type == Numeric) || (type == Boolean)
    end

  end

  module InstancePersistence
    attr_accessor :id

    def initialize
      @id = nil
    end

    def save!
      define_singleton_method(:refresh!) {self.class.refresh!(self)}
      self.class.save!(self)
    end

    def refresh!
      raise("Este objeto no tiene id!")
    end

    def forget!
      self.class.forget!(self)
    end

    def getFromDB
      self.class.getFromDB(self)
    end

    def to_hash
      self.class.to_hash(self)
    end

  end
end


module TADB
  class Table
    def upsert(object)
      if persisted? object
        update object
      else
        insert(object)
      end
    end

    def update(object)
      delete(object.id)
      insert(object)
    end

    def persisted?(object)
      entries.any? { |(key, value)| key == "id" && value == object.id }
    end
  end
end

class SimpleField
  attr_accessor :type, :name
  def initialize(type, name)
    @type = type
    @name = name
  end

  def get_field(instance)
    instance.send("#{@name}")
  end

  def assign(instance, value)
    instance.send("#{@name}=", value)
  end

  def save! (instance)
    field = get_field(instance)
    hash = {}
    hash[name] = field
    hash
  end

  def refresh!(instance)
    actualInstance = instance.getFromDB()
    instance.send("#{@name}=", actualInstance[name])
  end
end

class ComplexField
  attr_accessor :type, :name
  def initialize(type, name)
    @type = type
    @name = name
  end

  def get_field(instance)
    instance.send("#{@name}")
  end

  def assign(instance, value)
    instance.send("#{@name}=", type.find_by_id(value).first)
  end

  def save! (instance)
    has_object = get_field(instance)
    id = has_object.save!
    hash = {}
    hash[name] = id
    hash
  end

  def refresh!(instance)
    has_object = get_field(instance)
    has_object.refresh!
    instance.send("#{@name}=", has_object)
  end
end