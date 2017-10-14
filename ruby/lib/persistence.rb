require 'tadb'
require_relative './boolean.rb'
require_relative './fields.rb'
require_relative './table.rb'
require_relative './c_persistence.rb'
require_relative './instance_persistence.rb'

module Persistence

  def self.included(base)
    base.extend ClassPersistence
    base.include InstancePersistence
  end
end