require_relative("../lib/persistence")

class Fixture
  def person
    person = Person.new
    person.first_name = "gonza"
    person.last_name = "esc"
    person.age = 20
    person.animal = animal
    aBook = book
    anotherBook = book
    person.books = [aBook, anotherBook]
    person
  end

  def animal
    animal = Animal.new
    animal.first_name = "juno"
    animal.last_name = "esc"
    animal.age = 1
    animal
  end

  def book
    book = Book.new
    book.name = "harry"
    book
  end


  def validation
    validation = Validations.new
    validation.num = 28
    validation.string = "asd"
    validation.bool = true
    aBook = book
    anotherBook = book
    validation.books = [aBook, anotherBook]
    validation.animal = animal
    validation
  end


end

class Book
  include Persistence
  has_one String, named: :name
end

class Animal
  include Persistence
  has_one String, named: :first_name
  has_one String, named: :last_name
  has_one Numeric, named: :age

end


class Person
  include Persistence
  has_one Animal, named: :animal
  has_one String, named: :first_name
  has_one String, named: :last_name
  has_one Numeric, named: :age
  has_many Book, named: :books
end

class Validations
  include Persistence
  has_one Numeric, named: :num, from: 18, to: 100
  has_one String, named: :string
  has_one Boolean, named: :bool, no_blank: true
  has_many Book, named: :books
  has_one Animal, named: :animal,validate: proc{ age > 0 }
  has_one String, named: :default_string, default: "asd"
end




