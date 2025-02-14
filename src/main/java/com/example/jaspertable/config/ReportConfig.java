package com.example.jaspertable.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.Getter;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.io.InputStream;
import java.util.Map;

@Component
@Getter
public class ReportConfig {

    private Map<String, Object> config;

    @PostConstruct
    public void loadConfig() throws IOException {
        String configPath = System.getenv("CONFIG_PATH");
        if (configPath == null || configPath.isEmpty()) {
            configPath = "configs/config.json"; // Default path inside resources
        }

        InputStream configStream = getClass().getClassLoader().getResourceAsStream(configPath);
        if (configStream == null) {
            throw new IOException("❌ Configuration file not found: " + configPath);
        }

        ObjectMapper objectMapper = new ObjectMapper();
        config = objectMapper.readValue(configStream, Map.class);

        System.out.println("✅ Report configuration loaded successfully!");
    }
}
