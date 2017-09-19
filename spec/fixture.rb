require_relative("../src/persistence")

class Fixture
  def person
    person = Person.new
    person.first_name = "gonza"
    person.last_name = "esc"
    person.age = 20
    person
  end
end

class Person < ActiveRecord
  has_one String, named: :first_name
  has_one String, named: :last_name
  has_one Numeric, named: :age
end