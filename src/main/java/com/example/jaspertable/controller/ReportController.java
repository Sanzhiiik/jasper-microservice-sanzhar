package com.example.jaspertable.controller;

import com.example.jaspertable.config.ReportConfig;
import com.example.jaspertable.service.JReportService;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
@RequestMapping("/report")
public class ReportController {

    private final JReportService jReportService;
    private final ReportConfig reportConfig;  // Inject the configuration component

    @PostMapping("/generate")
    public void generateReport(@RequestBody Map<String, Object> requestBody, HttpServletResponse response) throws IOException {
        try {
            // Get the expected structure for the report from the config
            Map<String, Object> expectedStructure = (Map<String, Object>) reportConfig.getConfig();

            // Validate the request body against the expected structure
            if (validateRequestStructure(requestBody, expectedStructure)) {
                // Pass the report data directly to the service
                jReportService.exportJasperReport(requestBody, response);
            } else {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid request structure for report: ");
            }

        } catch (Exception e) {
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Error generating report: " + e.getMessage());
        }
    }

    @PostMapping("/generateAnketa")
    public void generateAnketa(@RequestBody Map<String, Object> requestBody, HttpServletResponse response) throws IOException {


        jReportService.generateAnketa(requestBody, response);

    }

    @PostMapping("/generateAnketa1")
    public void generateAnketa1(@RequestBody List<Map<String, ?>> requestBody, HttpServletResponse response) throws IOException {


        jReportService.generateAnketa1(requestBody, response);

    }

    @PostMapping("generateSubreport")
    public void generateSubreport(@RequestBody Map<String, Object> requestBody, HttpServletResponse response) throws IOException {
        jReportService.generateSubreport(requestBody, response);
    }

    // Method to validate the structure of the request body
    private boolean validateRequestStructure(Map<String, Object> requestBody, Map<String, Object> expectedStructure) {
        // Check if all expected keys are present in the request body
        for (String key : expectedStructure.keySet()) {
            if (!requestBody.containsKey(key)) {
                return false;
            }
        }
        return true;
    }
}
