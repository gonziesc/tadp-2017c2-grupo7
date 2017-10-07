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

    def field_exists?(name)
      return sticky_fields.any? {|field| field.name == name}
    end

    def change_field_type(name, type)
      sticky_fields.find{|field| field.name == name}.type = type
    end

    def has(new_field, type)
      if(field_exists? new_field.name)
        change_field_type(new_field.name, type)
      else
        attr_accessor(new_field.name)
        sticky_fields << new_field
      end
    end

    def has_one (type, hash)
      new_field = primitive?(type) ? SimpleField.new(type, hash) : ComplexField.new(type, hash)
      has(new_field, type)
    end

    def has_many(type, hash)
      new_field=  ManyField.new(type, hash)
      has(new_field, type)
    end

    def validate!(instance)
      sticky_fields.each {|field| (field.validate!(instance)) }
    end

    def save!(instance)
      validate!(instance)
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

    def validate!
      self.class.validate!(self)
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

class Field
  attr_accessor :type, :name, :validations
  def initialize(type, hash)
    @type = type
    @name = hash[:named]
    @validations = hash.reject!{ |k| k == :named }
  end

  def get_field(instance)
    instance.send("#{@name}")
  end

  def validate!(instance)
    validate_type(get_field(instance))
    @validations.each {|name, value| send(name, value, get_field(instance))}
  end

  def validate (proc, value)
    unless value.instance_eval(&proc)
      raise("Error de tipos")
    end
  end

  def validate_type(value)
    unless value.is_a? type
      raise("Error de tipos")
    end
  end

end

class SimpleField < Field

  def no_blank (validation, value)
    if value.is_a? Boolean and validation == true
      if value == nil or value == ""
        raise("Error de tipos")
      end
    end
  end

  def from (validation, value)
    if value.is_a? Numeric
      if value < validation
        raise("Error de tipos")
      end
    end
  end

  def to (validation, value)
    if value.is_a? Numeric
      if value > validation
        raise("Error de tipos")
      end
    end
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

class ComplexField < Field

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

  def validate_type(value)
    super(value)
    value.validate!
  end

end

class ManyField < Field

  def assign(instance, value)
    instances = @ids.map {|id| type.find_by_id(id).first }
    instance.send("#{@name}=", instances)
  end

  def save! (instance)
    has_object = get_field(instance)
    @ids = has_object.map {|object| object.save!}
    table_name = instance.class.name + "_" + @name.to_s
    @table = TADB::DB.table(table_name)
    @ids.each {|id| @table.insert( {"foreign_key" => id})}
    hash = {}
    hash[name] = table_name
    hash
  end

  def refresh!(instance)
    has_object = get_field(instance)
    has_object.each {|object| object.refresh!}
    instance.send("#{@name}=", has_object)
  end

  def validate_type(array)
    unless array.all? {|object| object.is_a? type}
      raise("Error de tipos")
    end
    array.each{|object| object.validate!}
  end
end