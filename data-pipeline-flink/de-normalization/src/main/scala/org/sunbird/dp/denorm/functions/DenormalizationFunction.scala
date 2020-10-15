package org.sunbird.dp.denorm.functions

import java.lang

import org.apache.flink.api.common.typeinfo.TypeInformation
import org.apache.flink.configuration.Configuration
import org.apache.flink.streaming.api.functions.ProcessFunction
import org.apache.flink.streaming.api.functions.windowing.ProcessWindowFunction
import org.slf4j.LoggerFactory
import org.sunbird.dp.core.job.{BaseProcessFunction, Metrics, WindowBaseProcessFunction}
import org.sunbird.dp.denorm.`type`._
import org.sunbird.dp.denorm.domain.Event
import org.sunbird.dp.denorm.task.DenormalizationConfig
import org.sunbird.dp.denorm.util.DenormCache
import org.sunbird.dp.core.cache.RedisConnect
import org.apache.flink.streaming.api.windowing.windows.TimeWindow
import org.joda.time.DateTime

import scala.collection.JavaConverters._

class DenormalizationFunction(config: DenormalizationConfig)(implicit val mapTypeInfo: TypeInformation[Event])
  extends WindowBaseProcessFunction[Event, Event, String](config) {

  private[this] val logger = LoggerFactory.getLogger(classOf[DenormalizationFunction])

  private[this] var deviceDenormalization: DeviceDenormalization = _
  private[this] var userDenormalization: UserDenormalization = _
  private[this] var dialcodeDenormalization: DialcodeDenormalization = _
  private[this] var contentDenormalization: ContentDenormalization = _
  private[this] var locationDenormalization: LocationDenormalization = _
  private[this] var denormCache: DenormCache = _


  override def metricsList(): List[String] = {
    List(config.eventsExpired, config.userTotal, config.userCacheHit, config.userCacheMiss,
      config.contentTotal, config.contentCacheHit, config.contentCacheMiss, config.deviceTotal,
      config.deviceCacheHit, config.deviceCacheMiss, config.dialcodeTotal,
      config.dialcodeCacheHit, config.dialcodeCacheMiss,
      config.locTotal, config.locCacheHit, config.locCacheMiss)
  }

  override def open(parameters: Configuration): Unit = {
    super.open(parameters)
    denormCache = new DenormCache(config, new RedisConnect(config.metaRedisHost, config.metaRedisPort1, config), new RedisConnect(config.metaRedisHost, config.metaRedisPort2, config), new RedisConnect(config.metaRedisHost, config.metaRedisPort3, config), new RedisConnect(config.metaRedisHost, config.metaRedisPort4, config))
    denormCache.init()
    deviceDenormalization = new DeviceDenormalization(config)
    userDenormalization = new UserDenormalization(config)
    dialcodeDenormalization = new DialcodeDenormalization(config)
    contentDenormalization = new ContentDenormalization(config)
    locationDenormalization = new LocationDenormalization(config)
  }

  override def close(): Unit = {
    super.close()
    denormCache.close()
    deviceDenormalization.closeDataCache()
    userDenormalization.closeDataCache()
    dialcodeDenormalization.closeDataCache()
    contentDenormalization.closeDataCache()
  }

//  override def processElement(event: Event,
//                              context: ProcessFunction[Event, Event]#Context,
//                              metrics: Metrics): Unit = {
//    if (event.isOlder(config.ignorePeriodInMonths)) { // Skip events older than configured value (default: 3 months)
//      metrics.incCounter(config.eventsExpired)
//    } else {
//      if ("ME_WORKFLOW_SUMMARY" == event.eid() || !event.eid().contains("SUMMARY")) {
//        val cacheData = denormCache.getDenormData(event)
//        deviceDenormalization.denormalize(event, cacheData, metrics)
//        userDenormalization.denormalize(event, cacheData, metrics)
//        dialcodeDenormalization.denormalize(event, cacheData, metrics)
//        contentDenormalization.denormalize(event, cacheData, metrics)
//        locationDenormalization.denormalize(event, metrics)
//        context.output(config.denormEventsTag, event)
//      }
//    }
//  }

  override def process(key: String,
                       context: ProcessWindowFunction[Event, Event, String, TimeWindow]#Context,
                       elements: lang.Iterable[Event],
                       metrics: Metrics): Unit = {

    val eventsList = elements.asScala.toList
    println("EventsSize: " + eventsList.size + " key: " + key)
    logger.info("EventsSize" + elements.asScala.toList.size)
    val cacheData = denormCache.getDenormData(eventsList.head)
    elements.asScala.map { event =>
      if (event.isOlder(config.ignorePeriodInMonths)) { // Skip events older than configured value (default: 3 months)
        metrics.incCounter(config.eventsExpired)
      } else {
        if ("ME_WORKFLOW_SUMMARY" == event.eid() || !event.eid().contains("SUMMARY")) {
          deviceDenormalization.denormalize(event, cacheData, metrics)
          userDenormalization.denormalize(event, cacheData, metrics)
          dialcodeDenormalization.denormalize(event, cacheData, metrics)
          contentDenormalization.denormalize(event, cacheData, metrics)
          locationDenormalization.denormalize(event, metrics)
          context.output(config.denormEventsTag, event)
        }
      }
    }
  }
}
