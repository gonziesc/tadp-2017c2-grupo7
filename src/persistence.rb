require 'tadb'

module Persistence

  def self.included base
    base.send :extend, ClassPersistence
    base.send :include, InstancePersistence
  end

  module ClassPersistence
    attr_accessor :persistable_fields
    def has_one type, hash
      @name = hash[:named]
      attr_accessor(@name)
      self.persistable_fields ? self.persistable_fields.push(@name) : self.persistable_fields = [@name]
    end
  end

  module InstancePersistence
    attr_accessor :table
    def save!
      @table = TADB::DB.table(self.class.name)
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
        raise Exception.new("Este objeto no tiene id!")
      end
    end

    private

    def create_id id
      self.instance_variable_set(:@id, id)
      self.define_singleton_method(:id) do
        id
      end
    end
  end
end