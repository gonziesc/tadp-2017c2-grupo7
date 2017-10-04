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
      @sticky_fields ||= { id: String }
    end

    def table
      @table ||= TADB::DB.table(name)
    end

    def has_one (type, hash)
      attr_accessor(hash[:named])
      sticky_fields[hash[:named]] = type
    end

    def save!(instance)
      id = table.upsert(instance)
      instance.instance_variable_set("@id", id)
    end

    def forget!(instance)
      table.delete(instance.id)
      instance.instance_variable_set("@id", nil)
    end

    def refresh!(instance)
      if (instance.id)
        savedInstance = table.entries.find{ |i| i[:id] == instance.id }
        sticky_fields.each do
        |name, type| instance.instance_variable_set("@#{name}", savedInstance[name])
        end
      else
        raise("Este objeto no tiene id!")
      end
    end

    def to_hash(instance)
      hash = {}
      sticky_fields.each {|name, type| hash[name] = instance.instance_variable_get("@#{name}")}
      hash
    end

    def all_instances
      table = TADB::DB.table(self.name)
      instances = table.entries.flat_map { |instance|  (create_new_instance instance) }
      instances
    end

    def create_new_instance (attributes)
      instance = self.new
      sticky_fields.each do
      |name, type| initialize_by_type instance, name, type, attributes
      end
      instance.instance_variable_set("@id", attributes[:id])
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

  end

  module InstancePersistence
    attr_accessor :id

    def initialize
      @id = nil
    end

    def save!
      self.class.save!(self)
    end

    def refresh!
      self.class.refresh!(self)
    end

    def forget!
      self.class.forget!(self)
    end

    def to_hash
      self.class.to_hash(self)
    end
  end
end


module TADB
  class Table
    def upsert(object)
      if (persisted? object)
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
      entries.any? { |(key, value)| key == "id" and value = object.id }
    end
  end
end