require 'tadb'
require_relative './boolean.rb'

module Persistence

  def self.included base
    base.send :extend, ClassPersistence
    base.send :include, InstancePersistence
  end

  module ClassPersistence
    attr_accessor :persistable_fields
    def has_one type, hash
      name = hash[:named]
      attr_accessor(name)
      @persistable_fields ||= []
      @persistable_fields << name
    end

    def all_instances
      instances = []
      table = TADB::DB.table(self.name)
      table.entries.each { |instance| instances << (self.createNewInstance instance) }
      instances
    end

    def createNewInstance attributes
      instance = self.new
      @persistable_fields.each.each { |field| instance.send("#{field}=", attributes[field]) }
      instance.create_id attributes[:id]
      instance
    end

    def method_missing(sym, *args, &block)
      method = sym.to_s
      if(method.start_with?("find_by"))
        puts method.chomp("find_by")
      end
      super(sym, *args, &block)
    end

  end

  module InstancePersistence
    attr_accessor :table

    def initialize
      @table = TADB::DB.table(self.class.name)
    end

    def save!
      hash = {}
      self.class.persistable_fields.each { |field| hash[field] = self.instance_eval("#{field}") }
      id = table.insert(hash)
      create_id id
    end

    def refresh!
      if @id
        instance = @table.entries.find{ |i| i[:id] == @id }
        self.class.persistable_fields.each { |field| self.send("#{field}=", instance[field])      }
      else
        raise("Este objeto no tiene id!")
      end
    end

    def forget!
      @table.delete(@id)
      remove_instance_variable(:@id)
    end

    def create_id id
      self.instance_variable_set(:@id, id)
      self.define_singleton_method(:id) do
        @id
      end
    end
  end
end