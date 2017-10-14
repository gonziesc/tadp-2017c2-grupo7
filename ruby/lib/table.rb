module TADB
  class Table
    def upsert(object)
      if persisted? object
        update object
      else
        insert(object)
      end
    end

    def db_path
      "./db/#{@name}.json"
    end


    def update(object)
      delete(object.id)
      insert(object)
    end

    def persisted?(object)
      entries.any? {|(key, value)| key == 'id' && value == object.id}
    end
  end
end