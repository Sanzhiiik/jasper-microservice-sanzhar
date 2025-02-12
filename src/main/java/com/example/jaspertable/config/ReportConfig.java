package com.example.jaspertable.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.Getter;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;

import java.io.File;
import java.io.IOException;
import java.util.Map;

@Component
@Getter
public class ReportConfig {

    private Map<String, Object> config;

    @PostConstruct
    public void loadConfig() throws IOException {
        String configPath = System.getenv("CONFIG_PATH");
        if (configPath == null || configPath.isEmpty()) {
            configPath = "D:\\IdeaProjects\\Jasper-table\\templ\\config.json"; // Default path
        }

        File configFile = new File(configPath);
        if (!configFile.exists()) {
            throw new IOException("❌ Configuration file not found at: " + configPath);
        }

        ObjectMapper objectMapper = new ObjectMapper();
        config = objectMapper.readValue(configFile, Map.class);

        System.out.println("✅ Report configuration loaded successfully!");
    }
}
