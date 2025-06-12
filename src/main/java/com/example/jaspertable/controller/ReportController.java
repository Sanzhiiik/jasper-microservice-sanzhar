package com.example.jaspertable.controller;

import com.example.jaspertable.exception.BadRequestException;
import com.example.jaspertable.exception.ReportGenerationException;
import com.example.jaspertable.exception.ResourceNotFoundException;
import com.example.jaspertable.service.JReportService;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
@RequestMapping("/generate/report")
@Slf4j
public class ReportController {

    private final JReportService jReportService;

    /**
     * Generates a report with the given file name using the provided data.
     *
     * @param requestBody the data to include in the report
     * @param fileName    the name of the report file/template to use
     * @param response    the HTTP response to write the report to
     */
    @PostMapping("/{file_name}")
    public void generateResultsReport(
            @RequestBody LinkedHashMap<String, List<Map<String, Object>>> requestBody,
            @PathVariable("file_name") String fileName,
            HttpServletResponse response) {
        
        log.info("Generating report for file: {}", fileName);
        
        if (requestBody == null || requestBody.isEmpty()) {
            throw new BadRequestException("Report data cannot be empty");
        }
        
        try {
            jReportService.automated(fileName, requestBody, response);
            log.info("Report generated successfully for file: {}", fileName);
        } catch (IOException e) {
            log.error("IO error while generating report: {}", e.getMessage(), e);
            throw new ReportGenerationException("Error writing report to response", e);
        } catch (Exception e) {
            log.error("Error generating report: {}", e.getMessage(), e);
            throw ReportGenerationException.forFile(fileName, e);
        }
    }
}
