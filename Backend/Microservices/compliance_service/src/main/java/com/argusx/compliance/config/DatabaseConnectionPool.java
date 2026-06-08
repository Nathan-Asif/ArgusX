package com.argusx.compliance.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Lab 2 — Singleton: centralised Supabase/PostgreSQL connection lifecycle.
 * One pool instance per JVM; prevents duplicate connection leaks.
 */
@Component
public class DatabaseConnectionPool {

    private static volatile DatabaseConnectionPool instance;

    private final String databaseUrl;
    private final boolean databaseEnabled;
    private boolean connected;

    private DatabaseConnectionPool(
            @Value("${argusx.database.url:}") String databaseUrl,
            @Value("${argusx.database.enabled:false}") boolean databaseEnabled
    ) {
        this.databaseUrl = databaseUrl;
        this.databaseEnabled = databaseEnabled && databaseUrl != null && !databaseUrl.isBlank();
        this.connected = false;
    }

    /** Spring-managed construction delegates to the singleton accessor. */
    public static DatabaseConnectionPool getInstance(
            String databaseUrl,
            boolean databaseEnabled
    ) {
        if (instance == null) {
            synchronized (DatabaseConnectionPool.class) {
                if (instance == null) {
                    instance = new DatabaseConnectionPool(databaseUrl, databaseEnabled);
                }
            }
        }
        return instance;
    }

    public synchronized void connect() {
        if (connected) {
            return;
        }
        if (databaseEnabled) {
            // JDBC handshake placeholder — wire to Supabase when credentials are provided.
            connected = true;
        }
    }

    public synchronized void disconnect() {
        connected = false;
    }

    public boolean isConnected() {
        return connected;
    }

    public boolean isConfigured() {
        return databaseEnabled;
    }

    public String getDatabaseUrl() {
        return databaseUrl;
    }
}
