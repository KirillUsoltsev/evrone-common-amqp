def delete_queue(q)
  Evrone::Common::AMQP.logger.info "[amqp##{q.channel.id}] delete queue #{q.inspect[0..30]}"
  if q
    q.purge
    q.delete if_unused: false, if_empty: false
  end
  true
end

def delete_exchange(x)
  Evrone::Common::AMQP.logger.info "[amqp##{x.channel.id}] delete exchnage #{x.inspect[0..30]}"
  x.delete if x
  true
end

