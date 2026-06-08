package com.argusx.compliance.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class DatabasePoolConfig {

    @Bean
    public DatabaseConnectionPool databaseConnectionPool(
            @Value("${argusx.database.url:}") String databaseUrl,
            @Value("${argusx.database.enabled:false}") boolean databaseEnabled
    ) {
        return DatabaseConnectionPool.getInstance(databaseUrl, databaseEnabled);
    }
}
