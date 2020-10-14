package org.sunbird.dp.core.serde

import java.nio.charset.StandardCharsets
import java.util

import com.google.gson.Gson
import org.apache.flink.api.common.typeinfo.TypeInformation
import org.apache.flink.api.java.typeutils.TypeExtractor
import org.apache.flink.streaming.connectors.kafka.{KafkaDeserializationSchema, KafkaSerializationSchema}
import org.apache.kafka.clients.consumer.ConsumerRecord
import org.apache.kafka.clients.producer.ProducerRecord
import org.sunbird.dp.core.domain.Events
import org.sunbird.dp.core.util.JSONUtil

import scala.reflect.{ClassTag, classTag}

class EventDeserializationSchema[T <: Events](implicit ct: ClassTag[T]) extends KafkaDeserializationSchema[T] {
  private val serialVersionUID = - 7339003654529835367L
  override def isEndOfStream(nextElement: T): Boolean = false

  override def deserialize(record: ConsumerRecord[Array[Byte], Array[Byte]]): T = {
    // val parsedString = new String(record.value(), StandardCharsets.UTF_8)
    // val result = new Gson().fromJson(parsedString, new util.HashMap[String, AnyRef]().getClass)
    val recordMap = JSONUtil.deserialize[util.HashMap[String, AnyRef]](record.value())
    recordMap.put("partition",record.partition().asInstanceOf[AnyRef] )
//    val result = JSONUtil.deserialize[util.HashMap[String, AnyRef]](record.value())
    ct.runtimeClass.getConstructor(classOf[util.Map[String, AnyRef]]).newInstance(recordMap).asInstanceOf[T]
  }

  override def getProducedType: TypeInformation[T] = TypeExtractor.getForClass(classTag[T].runtimeClass).asInstanceOf[TypeInformation[T]]
}

class EventSerializationSchema[T <: Events : Manifest](topic: String) extends KafkaSerializationSchema[T] {
  private val serialVersionUID = -4284080856874185929L

  override def serialize(element: T, timestamp: java.lang.Long): ProducerRecord[Array[Byte], Array[Byte]] = {
    new ProducerRecord[Array[Byte], Array[Byte]](topic, Option(element.kafkaKey()).map(_.getBytes(StandardCharsets.UTF_8)).orNull,
      element.getJson().getBytes(StandardCharsets.UTF_8))
  }
}
