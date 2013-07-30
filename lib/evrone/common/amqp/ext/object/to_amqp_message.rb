class Object
  def to_amqp_message(options = {})
    Evrone::Common::AMQP::Message.new(self, options)
  end
end
