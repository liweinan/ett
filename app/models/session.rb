if Rails::VERSION::STRING < "4"
  class Session
    attr_accessor :email, :password
  end
else
  class Session
    include ActiveModel::Conversion
    include ActiveModel::Validations
    extend ActiveModel::Naming

    attr_accessor :email, :password

    def persisted?
      false
    end
  end
end
