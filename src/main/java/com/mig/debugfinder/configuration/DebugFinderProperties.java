package com.mig.debugfinder.configuration;

import com.mig.debugfinder.model.Server;
import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Data
@Configuration
@ConfigurationProperties(prefix = "debug-finder")
public class DebugFinderProperties {
    private List<Server> servers;
}
