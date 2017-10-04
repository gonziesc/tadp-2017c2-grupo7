require 'tadb'
require_relative './boolean.rb'

module Persistence

  def self.included (base)
    base.extend ClassPersistence
    base.include InstancePersistence
  end

  module ClassPersistence
    attr_accessor :primitive_sticky_fields, :table, :complex_sticky_fields
    def primitive_sticky_fields
      @primitive_sticky_fields ||= { id: String }
    end

    def complex_sticky_fields
      @complex_sticky_fields ||= {}
    end

    def table
      @table ||= TADB::DB.table(name)
    end

    def has_one (type, hash)
      primitive?(type) ? primitive_sticky_fields[hash[:named]] = type : complex_sticky_fields[hash[:named]] = type
      attr_accessor(hash[:named])
    end

    def save!(instance)
      complex_sticky_fields.each do |name, _|
        instance.send(name).save!
      end
      instance.id = table.upsert(instance)
    end

    def forget!(instance)
      table.delete(instance.id)
      instance.id = nil
    end

    def refresh!(instance)
      saved_instance_hash = table.entries.find{ |i| i[:id] == instance.id }
      primitive_sticky_fields.each do |name, _|
        instance.send("#{name}=", saved_instance_hash[name])
      end
      complex_sticky_fields.each do |name, type|
        sub_instance = type.new
        sub_instance.id = saved_instance_hash[name]
        sub_instance.refresh!
        instance.send("#{name}=", sub_instance)
      end
    end

    def to_hash(instance)
      hash = {}
      primitive_sticky_fields.each { |name, _| hash[name] = instance.send(name)}
      complex_sticky_fields.each { |name, _| hash[name] = instance.send(name).id}
      hash
    end

    def all_instances
      table = TADB::DB.table(self.name)
      instances = table.entries.map { |instance| (create_new_instance instance) }
      instances
    end

    def create_new_instance (attributes)
      instance = self.new
      attributes.each do |name, value|
        instance.send("#{name}=", value)
      end
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
      (type == String) || (type == Integer) || (type == Boolean)
    end

    def attribute_exists?(attribute)
      primitive_sticky_fields.keys.any? { |key| key == attribute} || complex_sticky_field.keys.any? {|key| key == attribute}
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
      # raise("Este objeto no tiene id!")
      self.class.refresh!(self)
    end

    def forget!
      self.class.forget!(self)
    end

    def to_hash
      self.class.to_hash(self)
    end

    def primitive_sticky_fields
      self.class.primitive_sticky_fields
    end

    def complex_sticky_fields
      self.class.complex_sticky_fields
    end

  end
end


module TADB
  class Table
    def upsert(object)
      if persisted? object
        update object
      else
        insert(object.to_hash)
      end
    end

    def update(object)
      delete(object.id)
      insert(object.to_hash)
    end

    def persisted?(object)
      entries.any? { |(key, value)| key == "id" && value == object.id }
    end
  end
end

class Auto
  include Persistence
  has_one String, named: :marca
end

class Persona
  include Persistence
  has_one String, named: :nombre
  has_one Integer, named: :edad
  has_one Auto, named: :auto
end

pers_a = Persona.new
pers_b = Persona.new
pers_a.nombre = "Pedro"
pers_a.edad = 10
pers_a.auto = Auto.new
pers_a.auto.marca = "Audi"
pers_a.save!
pers_b.id = pers_a.id
pers_b.refresh!
puts pers_b.to_hash
puts pers_b.auto.marca
