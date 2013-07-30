def delete_queue(q)
  Evrone::Common::AMQP.logger.info "[amqp:test] delete queue #{q.inspect[0..30]}"
  if q
    begin
      q.purge
      q.delete if_unused: false, if_empty: false
    rescue Bunny::NotFound,Bunny::ChannelAlreadyClosed => e
      Evrone::Common::AMQP.logger.error e.to_s
    end
  end
  true
end

def delete_exchange(x)
  Evrone::Common::AMQP.logger.info "[amqp:test] delete exchnage #{x.inspect[0..30]}"
  begin
    x.delete if x
  rescue Bunny::NotFound,Bunny::ChannelAlreadyClosed => e
    Evrone::Common::AMQP.logger.error e.to_s
  end
  true
end

