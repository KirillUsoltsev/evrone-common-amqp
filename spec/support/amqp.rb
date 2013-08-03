def delete_queue(q)
  Evrone::Common::AMQP.logger.info "[AMQP] delete queue #{q.inspect[0..30]}"
  if q
    q.purge
    q.delete if_unused: false, if_empty: false
  end
  true
end

def delete_exchange(x)
  Evrone::Common::AMQP.logger.info "[AMQP] delete exchnage #{x.inspect[0..30]}"
  x.delete if x
  true
end

