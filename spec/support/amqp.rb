def delete_queue(q)
  Evrone::Common::AMQP.logger.info "[amqp:test] delete queue #{q.inspect[0..30]}"
  q.purge
  q.delete if_unused: false, if_empty: false
  true
end

def delete_exchange(x)
  Evrone::Common::AMQP.logger.info "[amqp:test] delete exchnage #{x.inspect[0..30]}"
  x.delete
  true
end

