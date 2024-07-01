class Xid8Type < ActiveRecord::Type::Value
  def cast(value)
    value.to_s
  end

  def serialize(value)
    value.to_s
  end

  def deserialize(value)
    value.to_s
  end
end

ActiveRecord::Type.register(:xid8, Xid8Type)
