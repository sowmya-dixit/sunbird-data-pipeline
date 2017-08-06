package org.ekstep.ep.samza.task;

import org.apache.samza.config.Config;

public class EsIndexerSecondaryConfig {

    private final String failedTopic;
    private final String elasticSearchHost;
    private final String elasticSearchPort;
    private final String defaultIndexName;
    private final String defaultIndexType;

    public EsIndexerSecondaryConfig(Config config) {
        failedTopic = config.get("output.failed.topic.name", "telemetry.es-sink-secondary.fail");
        elasticSearchHost = config.get("host.elastic_search","localhost");
        elasticSearchPort = config.get("port.elastic_search","9200");
        defaultIndexName = config.get("default.failed.index_name","failed-telemetry-retry");
        defaultIndexType = config.get("default.failed.index_type","events");
    }

    public String failedTopic() {
        return failedTopic;
    }

    public String esHost() {
        return elasticSearchHost;
    }

    public int esPort() {
        return Integer.parseInt(elasticSearchPort);
    }

    public String getDefaultIndexName() { return defaultIndexName; }

    public String getDefaultIndexType() { return defaultIndexType; }
}
