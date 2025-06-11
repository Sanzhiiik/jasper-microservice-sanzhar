package com.example.jaspertable.service;

import jakarta.servlet.http.HttpServletResponse;
import net.sf.jasperreports.engine.*;
import net.sf.jasperreports.engine.data.JRMapCollectionDataSource;
import org.springframework.stereotype.Service;
import org.slf4j.Logger; // Import Logger
import org.slf4j.LoggerFactory; // Import LoggerFactory
import org.springframework.http.MediaType; // For setting content type

import java.io.IOException; // Be more specific with exceptions
import java.io.InputStream;
import java.util.*;

@Service
public class JReportService {

    // Initialize Logger for this class
    private static final Logger log = LoggerFactory.getLogger(JReportService.class);

    public void automated(String file_name, LinkedHashMap<String, List<Map<String, Object>>> data, HttpServletResponse response) throws IOException {
        log.info("Starting automated report generation for file: '{}'", file_name);
        String full_file_name = file_name.trim().toLowerCase() + ".jrxml";
        log.debug("Full report template file name expected: {}", full_file_name);

        if (data == null || data.isEmpty()) {
            log.warn("Input data for report generation is null or empty for file: '{}'. Throwing IllegalArgumentException.", file_name);
            throw new IllegalArgumentException("Data list cannot be empty");
        }
        log.debug("Received data for report generation: {}", data.keySet());

        /* Map of InputStreams     */
        LinkedHashMap<String, InputStream> inputStreamMap = new LinkedHashMap<>();
        log.debug("Initialized inputStreamMap.");

        try {
            /*Validate the existence of templates and put templates into the map of InputStreams*/
            log.info("Loading report templates into InputStreams.");
            loadReportTemplatesIntoInputStreams(inputStreamMap, data);
            log.info("Successfully loaded {} report templates into InputStreams.", inputStreamMap.size());

            /*compile the all the input streams in the InputStream map, then put them into the new map of the JasperReport*/
            LinkedHashMap<String, JasperReport> compiledReports = new LinkedHashMap<>();
            log.info("Compiling InputStreams into JasperReports.");
            loadInputStreamsIntoJasperReports(inputStreamMap, compiledReports);
            log.info("Successfully compiled {} JasperReports.", compiledReports.size());

            // Prepare lists for dynamic subreports
            List<JasperReport> subreportSources = new ArrayList<>();
            List<JRDataSource> subreportDataSources = new ArrayList<>();
            log.debug("Preparing lists for dynamic subreports.");

            for (Map.Entry<String, List<Map<String, Object>>> stringListEntry : data.entrySet()) {
                String templateKey = stringListEntry.getKey();
                List<Map<String, Object>> values = stringListEntry.getValue();

                JasperReport subreport = compiledReports.get(templateKey);
                if (subreport == null) {
                    log.warn("Compiled report for key '{}' not found. Skipping subreport generation for this key.", templateKey);
                    continue;
                }
                log.debug("Processing subreport for key: '{}' with {} data entries.", templateKey, values.size());

                for (Map<String, Object> value : values) {
                    subreportSources.add(subreport);
                    JRMapCollectionDataSource dataSource = new JRMapCollectionDataSource(Collections.singletonList(value));
                    subreportDataSources.add(dataSource);
                    log.trace("Added subreport '{}' and its data source to lists.", templateKey);
                }
            }
            log.debug("Finished preparing subreport sources and data sources. Total subreports: {}", subreportSources.size());

            Map<String, Object> parameters = new HashMap<>(data);
            parameters.put("SubreportSources", subreportSources);
            parameters.put("SubreportDataSources", subreportDataSources);
            log.debug("Prepared report parameters.");

            // Fill the report with data
            JasperReport masterReport = compiledReports.get("master");
            if (masterReport == null) {
                log.error("Master report template 'master.jrxml' not found in compiled reports. Cannot fill report.");
                throw new JRException("Master report 'master.jrxml' is missing.");
            }
            JRDataSource mainDataSource = new JREmptyDataSource(subreportSources.size());
            log.info("Filling Jasper report with master template and data.");
            JasperPrint jasperPrint = JasperFillManager.fillReport(masterReport, parameters, mainDataSource);
            log.info("Jasper report filled successfully.");

            // Set response headers
            response.setContentType(MediaType.APPLICATION_PDF_VALUE);
            response.setHeader("Content-Disposition", "attachment; filename=\"" + file_name.trim().toLowerCase() + ".pdf\"");
            log.debug("Set response headers: Content-Type='{}', Content-Disposition='attachment; filename=\"{}\"'", MediaType.APPLICATION_PDF_VALUE, file_name.trim().toLowerCase() + ".pdf");

            // Export PDF
            log.info("Exporting Jasper report to PDF stream.");
            JasperExportManager.exportReportToPdfStream(jasperPrint, response.getOutputStream());
            response.getOutputStream().flush();
            log.info("Report exported and output stream flushed successfully for file: '{}'.", file_name);

        } catch (JRException e) {
            log.error("JasperReports error during report generation for file '{}': {}", file_name, e.getMessage(), e);
            // Re-throw or handle as per your application's error strategy
            throw new IOException("Failed to generate report due to JasperReports error", e);
        } catch (IOException e) {
            log.error("I/O error during report generation for file '{}': {}", file_name, e.getMessage(), e);
            throw e; // Re-throw the IOException
        } catch (Exception e) { // Catch any other unexpected exceptions
            log.error("An unexpected error occurred during report generation for file '{}': {}", file_name, e.getMessage(), e);
            throw new IOException("An unexpected error occurred during report generation", e); // Wrap and re-throw
        }
    }

    private void loadInputStreamsIntoJasperReports(LinkedHashMap<String, InputStream> inputStreamMap, LinkedHashMap<String, JasperReport> compiledReports) throws JRException {
        log.debug("Starting compilation of InputStreams to JasperReports. Total streams: {}", inputStreamMap.size());
        for (Map.Entry<String, InputStream> entry : inputStreamMap.entrySet()) {
            String templateName = entry.getKey();
            InputStream inputStream = entry.getValue();
            log.debug("Compiling template: '{}'", templateName);
            try {
                // Compile the report and put it into the map
                JasperReport compiledReport = JasperCompileManager.compileReport(inputStream);
                compiledReports.put(templateName, compiledReport);
                log.debug("Successfully compiled template: '{}'", templateName);
            } catch (JRException e) {
                log.error("Failed to compile template '{}': {}", templateName, e.getMessage(), e);
                throw e; // Re-throw to be caught by the calling method
            } finally {
                // It's good practice to close InputStreams once they are consumed, especially after compilation.
                // However, JasperReports might close them internally after compilation.
                // If you encounter issues with stream being closed too early, you might need to adjust.
                try {
                    if (inputStream != null) {
                        inputStream.close();
                        log.trace("Closed InputStream for template: '{}'", templateName);
                    }
                } catch (IOException ioException) {
                    log.warn("Failed to close InputStream for template '{}': {}", templateName, ioException.getMessage());
                }
            }
        }
        log.debug("Finished compiling all InputStreams.");
    }

    private void loadReportTemplatesIntoInputStreams(LinkedHashMap<String, InputStream> inputStreamMap, LinkedHashMap<String, List<Map<String, Object>>> data) throws JRException {
        log.debug("Starting to load report templates into InputStreams.");

        // Ensure master template is loaded first
        String masterTemplatePath = "reports/report/master.jrxml";
        InputStream masterStream = getClass().getClassLoader().getResourceAsStream(masterTemplatePath);
        if (masterStream == null) {
            log.error("Master report template not found: {}. Throwing JRException.", masterTemplatePath);
            throw new JRException("❌ Master report template not found: " + masterTemplatePath);
        }
        inputStreamMap.put("master", masterStream);
        log.debug("Loaded master template: '{}'", masterTemplatePath);

        // Load other required templates based on the data keys
        for (String key : data.keySet()) {
            // Only load if it's not the master key, as master is already handled
            if (!"master".equals(key)) {
                String templatePath = "reports/report/" + key.trim().toLowerCase() + ".jrxml";
                InputStream stream = getClass().getClassLoader().getResourceAsStream(templatePath);
                if (stream == null) {
                    log.error("Report template not found: {}. Throwing JRException.", templatePath);
                    throw new JRException("❌ Report template not found: " + templatePath);
                }
                // Only add if not already present (to avoid redundant additions if a key matches "master")
                if (!inputStreamMap.containsKey(key.trim().toLowerCase())) {
                    inputStreamMap.put(key.trim().toLowerCase(), stream);
                    log.debug("Loaded template: '{}'", templatePath);
                } else {
                    log.debug("Template '{}' already loaded, skipping redundant load.", templatePath);
                    // It's crucial to close streams if you're fetching them multiple times without using them
                    // or if they are replaced in the map.
                    try {
                        stream.close();
                    } catch (IOException e) {
                        log.warn("Failed to close redundant InputStream for '{}': {}", templatePath, e.getMessage());
                    }
                }
            }
        }
        log.debug("Finished loading all required report templates.");
    }

}