module Storage

class Storage
  def self.register(name, clazz)
    @storages ||= {}
    @storages[name.to_s] = clazz
    @storages[name.to_s.to_sym] = clazz
  end

  def store(options = {})
  end
end

class EncryptedStorage
  def store(options = {})
  end
end

class MongoStorage
  def store(options = {})
  end
end

class FileStorage
  def store(options = {})
  end
end

class S3Storage
  def store(options = {})
  end
end

class ClassMethods
end

def self.included(base)
  base.extend(ClassMethods)
end

end
