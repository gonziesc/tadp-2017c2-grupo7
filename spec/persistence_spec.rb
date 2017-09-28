require 'rspec'
require_relative("fixture.rb")

describe "persistence" do
  fixture = Fixture.new
  let!(:person) {fixture.person}
  let!(:bird) {fixture.bird}
  let!(:validation) {fixture.validation}

    after(:each) do
      if File.exist? "./db/Person"
       File.delete("./db/Person")
      end
      if File.exist? "./db/Animal"
        File.delete("./db/Animal")
      end
      if File.exist? "./db/Book"
        File.delete("./db/Book")
      end
      if File.exist? "./db/Person_books"
        File.delete("./db/Person_books")
      end
      if File.exist? "./db/Bird"
        File.delete("./db/Bird")
      end
      if File.exist? "./db/Validation"
        File.delete("./db/Validation")
      end
    end

    it "Should have replaced dummy attribute type" do
    expect(Dummy.sticky_fields[:dummy]).to eq(String)
    end

    it "Should have persistable attributes" do
      expect(person).to respond_to(:first_name)
      expect(person).to respond_to(:last_name)
      expect(person).to respond_to(:age)
    end

    it "Should not have other attributes" do
      expect(person).not_to respond_to(:saraza)
    end

  it "Should have persistable attributes" do
    expect(person.first_name).to eq("gonza")
    expect(person.age).to eq(20)
  end

  it "Should have id after save" do
    person.save!
    expect(person.id).not_to eq(nil)
  end

  it "Should change attribute after refreshing" do
    person.save!
    person.first_name = "asd"
    person.refresh!
    expect(person.first_name).to eq("gonza")
  end

  it "Should raise exception because of no saving" do
    person.first_name = "asd"
    expect{(person.refresh!)}.to raise_error("Este objeto no tiene id!")
   end

  it "Should forget id after forgetting" do
    person.save!
    person.forget!
    expect(person.id).to eq(nil)
  end

  it "Should bring 2 instances with all instances" do
    person.save!
    anotherPerson = fixture.person
    anotherPerson.save!
    personThatWontSave = fixture.person
    personThatWontSave.first_name = "nono"
    expect(Person.all_instances.size).to eq(2)
  end

  it "Should understand variables with all instances" do
    person.save!
    anotherPerson = fixture.person
    anotherPerson.save!
    expect(Person.all_instances.first).to respond_to(:first_name)
  end

  describe "find by" do

    before(:each) do
      person.save!
      anotherPerson = fixture.person
      anotherPerson.save!
      otherPerson = fixture.person
      otherPerson.save!
    end

    it "Should filter by first name bringing 3 instances" do
      expect(Person.find_by_first_name("gonza").size).to eq(3)
    end

    it "Should filter by first name bringing 0 instances" do
      expect(Person.find_by_first_name("asd").size).to eq(0)
    end

    it "Should filter by id bringing 1 instances" do
      expect(Person.find_by_id(person.id).size).to eq(1)
    end

    it "Should raise error method missing" do
      expect{(Person.find_by_asdasd())}.to raise_error("El metodo no existe o tiene parametros")
    end
  end

  describe "having persisting objetcs" do
    it "Should have persistable attributes" do
      expect(person.animal.first_name).to eq("juno")
      expect(person.animal.age).to eq(1)
    end

    it "Should have id after save" do
      person.save!
      expect(person.animal.id).not_to eq(nil)
    end

    it "Should have name after save" do
      person.save!
      expect(person.animal.age).to eq(1)
    end

    it "Should all instances bring the complete person" do
      person.save!
      expect(Person.all_instances.first.animal.age).to eq(1)
    end

    it "Should change attribute after refreshing" do
      person.save!
      animal = person.animal
      animal.age = 2
      animal.save!
      person.refresh!
      expect(person.animal.age).to eq(2)
    end
  end

  describe "has many" do
    it "Should have 3 books after adding one" do
      book = fixture.book
      person.books.push(book)
      person.books.last.name = "gonza"
      person.save!
      expect(person.books.last.name).to eq("gonza")
      expect(person.books.size).to eq(3)
    end
    it "Should refresh the last book" do
      book = fixture.book
      person.books.push(book)
      person.save!
      anotherBook = person.books.last
      anotherBook.name = "gonza"
      anotherBook.save!
      person.refresh!
      expect(person.books.last.name).to eq("gonza")
    end

    it "Should all instances bring the complete person" do
      person.save!
      expect(Person.all_instances.first.books.first.name).to eq("harry")
    end
  end

  describe "Should be correct with inheritance and mixins" do
    it "Should save animal and bird instances" do
      person.save!
      bird.save!
      expect(Animal.all_instances.size).to eq(2)
    end

    it "Should bring both animals with name juno" do
      person.save!
      bird.save!
      expect(Animal.find_by_first_name("juno").size).to eq(2)
    end

    ## not working: linealization of modules including persistence
  end

  describe "Should be correct with validations" do
    it "Should save the validations" do
      expect{(validation.save!)}.to_not raise_error()
    end

    it "Should fail the validations" do
      validation.num = "asd"
      expect{(validation.save!)}.to raise_error("Error de tipos")
    end

    it "Should fail the validations" do
      validation.num = "asd"
      expect{(validation.save!)}.to raise_error("Error de tipos")
    end

    it "Should fail the validations" do
      validation.string = 8
      expect{(validation.save!)}.to raise_error("Error de tipos")
    end

    it "Should fail the validations" do
      validation.bool = "asd"
      expect{(validation.save!)}.to raise_error("Error de tipos")
    end

    it "Should fail the validations" do
      validation.animal.first_name = 8
      expect{(validation.save!)}.to raise_error("Error de tipos")
    end

    it "Should fail the validations" do
      validation.books.first.name = 8
      expect{(validation.save!)}.to raise_error("Error de tipos")
    end

  end

end