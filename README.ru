## Evrone::Common::Amqp

Библитека для работы работы с RabbitMQ воркерами, сделана по мотивам sidekiq,
внутри используется gem bunny.

* [![Build Status](https://travis-ci.org/evrone/evrone-common-amqp.png?branch=master)](https://travis-ci.org/evrone/evrone-common-amqp)

## Requirements

* Ruby MRI 1.9.3, 2.0.0

## Instalation

Для установки

```shell
gem install evrone-common-amqp
```

или добавьте в Gemfile

```ruby
gem "evrone-common-amqp"
```

## Как работает

Добавьте консумера

```ruby
class ExampleConsumer

  include Evrone::Common::AMQP::Consumer

  # queue [ name ] [ options ]
  #
  # name         [String] имя очереди, поумолчанию используется имя консумера ("example")
  # options      [Hash]   параметры очереди, http://reference.rubybunny.info/Bunny/Queue.html#initialize-instance_method

  # exchange [ name ] [ options ]
  #
  # name         [String] имя exchange, по умолчанию используется имя консумера ("example")
  # options      [Hash]   параметры exchange, http://reference.rubybunny.info/Bunny/Exchange.html#initialize-instance_method

  # настройки роутинга
  #
  # routing_key  [String]
  # headers      [Hash]

  # десериализация
  #
  # model        [Class]  используется для десериализации, см ниже

  def perform(payload, properties)
    # ... hard work ...
  end
end

```

Для отправки сообщений

```ruby
# message    [Object]
# options    [Hash]  параметры отправки сообщения, http://reference.rubybunny.info/Bunny/Channel.html#basic_publish-instance_method
ExampleConsumer.publish message [, options ]
```

Для получения сообщений

```ruby
ExampleConsumer.subscribe
```

#### Сериализация

* Строки отправляются как есть
* Остальные объекты сериализуются в JSON используя метод ```#to_json```
* В ```headers``` сообщения добавляется поле ```content_type``` со значением 'application/json' или 'text/plain'

#### Десериализация

В зависимости от поля ```content_type```

* Если у консумера добавен параметр ```model ClassName```, то вызывается метод ```ClassName.from_json```
* Если ```content_type``` равен 'application/json', вызывается JSON.parse
* В остальных случаях сообщение передается как есть.


