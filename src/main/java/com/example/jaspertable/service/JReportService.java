package com.example.jaspertable.service;

import jakarta.servlet.http.HttpServletResponse;
import net.sf.jasperreports.engine.*;
import net.sf.jasperreports.engine.data.JRMapCollectionDataSource;
import org.apache.pdfbox.multipdf.PDFMergerUtility;
import org.springframework.stereotype.Service;
import org.slf4j.Logger; // Import Logger
import org.slf4j.LoggerFactory; // Import LoggerFactory
import org.springframework.http.MediaType; // For setting content type

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException; // Be more specific with exceptions
import java.io.InputStream;
import java.io.OutputStream;
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

            JasperReport masterReport = compiledReports.get("master");
            if (masterReport == null) {
                log.error("Master report template 'master.jrxml' not found in compiled reports. Cannot fill report.");
                throw new JRException("Master report 'master.jrxml' is missing.");
            }

            // Landscape-oriented templates (pageWidth > pageHeight, e.g. "participants") cannot be
            // embedded as a <subreport> in master.jrxml — a subreport always inherits the master's own
            // page geometry, so a wide table would just get cropped to the portrait page width.
            // Instead, keys are split into contiguous runs preserving the original order: portrait runs
            // are combined into one master-filled PDF exactly as before, while each landscape key is
            // filled standalone (with its own page size) into its own PDF. All the resulting PDFs are
            // then merged back together in order via PDFBox, since PDF pages may each carry their own size.
            List<byte[]> pdfChunks = new ArrayList<>();
            LinkedHashMap<String, List<Map<String, Object>>> portraitRun = new LinkedHashMap<>();

            for (Map.Entry<String, List<Map<String, Object>>> stringListEntry : data.entrySet()) {
                String templateKey = stringListEntry.getKey();
                List<Map<String, Object>> values = stringListEntry.getValue();

                JasperReport subreport = compiledReports.get(templateKey);
                if (subreport == null) {
                    log.warn("Compiled report for key '{}' not found. Skipping.", templateKey);
                    continue;
                }

                boolean isLandscape = subreport.getPageWidth() > subreport.getPageHeight();
                if (isLandscape) {
                    log.debug("Key '{}' is landscape-oriented ({}x{}); rendering it as a standalone section.",
                            templateKey, subreport.getPageWidth(), subreport.getPageHeight());
                    if (!portraitRun.isEmpty()) {
                        pdfChunks.add(renderPortraitRun(masterReport, portraitRun, compiledReports));
                        portraitRun.clear();
                    }
                    pdfChunks.add(renderStandaloneSection(templateKey, subreport, values));
                } else {
                    portraitRun.put(templateKey, values);
                }
            }
            if (!portraitRun.isEmpty()) {
                pdfChunks.add(renderPortraitRun(masterReport, portraitRun, compiledReports));
            }

            if (pdfChunks.isEmpty()) {
                log.error("No renderable sections were produced for file '{}'.", file_name);
                throw new JRException("No renderable sections found for the given data.");
            }

            // Set response headers
            response.setContentType(MediaType.APPLICATION_PDF_VALUE);
            response.setHeader("Content-Disposition", "attachment; filename=\"" + file_name.trim().toLowerCase() + ".pdf\"");
            log.debug("Set response headers: Content-Type='{}', Content-Disposition='attachment; filename=\"{}\"'", MediaType.APPLICATION_PDF_VALUE, file_name.trim().toLowerCase() + ".pdf");

            // Export PDF
            if (pdfChunks.size() == 1) {
                log.info("Writing single PDF section directly to response for file '{}'.", file_name);
                response.getOutputStream().write(pdfChunks.get(0));
            } else {
                log.info("Merging {} PDF sections into the final document for file '{}'.", pdfChunks.size(), file_name);
                mergePdfChunks(pdfChunks, response.getOutputStream());
            }
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

    /**
     * Fills master.jrxml with a contiguous run of portrait-oriented keys, exactly like the original
     * single-master-fill approach, and exports it to a PDF byte array.
     */
    private byte[] renderPortraitRun(JasperReport masterReport,
                                      LinkedHashMap<String, List<Map<String, Object>>> runData,
                                      Map<String, JasperReport> compiledReports) throws JRException, IOException {
        List<JasperReport> subreportSources = new ArrayList<>();
        List<JRDataSource> subreportDataSources = new ArrayList<>();

        for (Map.Entry<String, List<Map<String, Object>>> entry : runData.entrySet()) {
            JasperReport subreport = compiledReports.get(entry.getKey());
            subreportSources.add(subreport);
            subreportDataSources.add(new JRMapCollectionDataSource(new ArrayList<Map<String, ?>>(entry.getValue())));
            log.trace("Added subreport '{}' with a data source of {} records.", entry.getKey(), entry.getValue().size());
        }

        Map<String, Object> parameters = new HashMap<>();
        parameters.put("SubreportSources", subreportSources);
        parameters.put("SubreportDataSources", subreportDataSources);

        JRDataSource mainDataSource = new JREmptyDataSource(subreportSources.size());
        log.info("Filling master template with portrait run: {}", runData.keySet());
        JasperPrint jasperPrint = JasperFillManager.fillReport(masterReport, parameters, mainDataSource);

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        JasperExportManager.exportReportToPdfStream(jasperPrint, baos);
        return baos.toByteArray();
    }

    /**
     * Fills a landscape-oriented template on its own (not wrapped by master.jrxml), so it keeps its
     * own page size in the exported PDF instead of being cropped to the master's portrait width.
     */
    private byte[] renderStandaloneSection(String templateKey, JasperReport report, List<Map<String, Object>> values) throws JRException, IOException {
        JRDataSource dataSource = new JRMapCollectionDataSource(new ArrayList<Map<String, ?>>(values));
        log.info("Filling standalone landscape template '{}' with {} records.", templateKey, values.size());
        JasperPrint jasperPrint = JasperFillManager.fillReport(report, new HashMap<>(), dataSource);

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        JasperExportManager.exportReportToPdfStream(jasperPrint, baos);
        return baos.toByteArray();
    }

    /**
     * Merges PDF byte-array chunks, in order, into a single PDF written to the given output stream.
     * PDFBox preserves each source page's own size, so a landscape chunk stays landscape in the result.
     */
    private void mergePdfChunks(List<byte[]> pdfChunks, OutputStream out) throws IOException {
        PDFMergerUtility merger = new PDFMergerUtility();
        for (byte[] chunk : pdfChunks) {
            merger.addSource(new ByteArrayInputStream(chunk));
        }
        merger.setDestinationStream(out);
        merger.mergeDocuments(null);
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