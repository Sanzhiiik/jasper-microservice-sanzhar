package com.example.jaspertable.service;

import jakarta.servlet.http.HttpServletResponse;
import net.sf.jasperreports.engine.*;
import net.sf.jasperreports.engine.data.JRMapCollectionDataSource;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.util.*;

@Service
public class JReportService {

    private static final String REPORT_TEMPLATE = "reports/template.jrxml";
    private static final String ANKETA_TEMPLATE = "reports/anketa/anketa.jrxml";
    private static final String SUBREPORT_TEMPLATE = "reports/subreports/relatives.jrxml";
    private static final String SUBREPORT_MASTER_TEMPLATE = "reports/subreports/main-relatives.jrxml";
    private static final String SUBREPORT_MASTER_LIST_TEMPLATE = "reports/subreports/list-experiment.jrxml";// Correct path inside src/main/resources/

    public void exportJasperReport(Map<String, Object> data, HttpServletResponse response) {
        try {
            // Wrap data into a collection
            List<Map<String, ?>> dataList = Collections.singletonList(data);
            JRMapCollectionDataSource dataSource = new JRMapCollectionDataSource(dataList);

            // ✅ Load JRXML file correctly from resources
            InputStream reportStream = getClass().getClassLoader().getResourceAsStream(REPORT_TEMPLATE);
            if (reportStream == null) {
                throw new JRException("❌ Report template not found: " + REPORT_TEMPLATE);
            }

            // Compile the report
            JasperReport jasperReport = JasperCompileManager.compileReport(reportStream);


            // Fill the report with data
            JasperPrint jasperPrint = JasperFillManager.fillReport(jasperReport, data, dataSource);


            // Set response headers
            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition", "attachment; filename=Report.pdf");

            // Export PDF
            JasperExportManager.exportReportToPdfStream(jasperPrint, response.getOutputStream());

            response.getOutputStream().flush();
        } catch (Exception e) {
            e.printStackTrace();
            handleError(response, "Error generating report: " + e.getMessage(), e);
        }
    }

    public void generateAnketa(Map<String, Object> data, HttpServletResponse response) {
        try {
            // Wrap data into a collection
            List<Map<String, ?>> dataList = Collections.singletonList(data);
            JRMapCollectionDataSource dataSource = new JRMapCollectionDataSource(dataList);

            // ✅ Load JRXML file correctly from resources
            InputStream reportStream = getClass().getClassLoader().getResourceAsStream(ANKETA_TEMPLATE);
            if (reportStream == null) {
                throw new JRException("❌ Report template not found: " + ANKETA_TEMPLATE);
            }

            // Compile the report
            JasperReport jasperReport = JasperCompileManager.compileReport(reportStream);


            // Fill the report with data
            JasperPrint jasperPrint = JasperFillManager.fillReport(jasperReport, data, dataSource);


            // Set response headers
            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition", "attachment; filename=Anketa.pdf");

            // Export PDF
            JasperExportManager.exportReportToPdfStream(jasperPrint, response.getOutputStream());

            response.getOutputStream().flush();
        } catch (Exception e) {
            e.printStackTrace();
            handleError(response, "Error generating report: " + e.getMessage(), e);
        }
    }

    private void handleError(HttpServletResponse response, String message, Exception e) {
        try {
            if (!response.isCommitted()) {
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, message);
            }
        } catch (Exception ioException) {
            ioException.printStackTrace();
        }
        e.printStackTrace();
    }

    public void generateAnketa1(List<Map<String, ?>> data, HttpServletResponse response) {
        try {
            // Wrap data into a collection
//            List<Map<String, Object>> dataList = data;
            Collection<Map<String, ?>> firstDataSource = Collections.singletonList(data.get(0));
            Collection<Map<String, ?>> secondDataSource = Collections.singletonList(data.get(1));


            JRMapCollectionDataSource subreportDataSource1 = new JRMapCollectionDataSource(firstDataSource);
            JRMapCollectionDataSource subreportDataSource2 = new JRMapCollectionDataSource(secondDataSource);

            // ✅ Load master report from classpath
            InputStream mainReportStream = getClass().getClassLoader().getResourceAsStream(SUBREPORT_MASTER_LIST_TEMPLATE);
            if (mainReportStream == null) {
                throw new JRException("❌ Master report template not found: " + SUBREPORT_MASTER_TEMPLATE);
            }

            // ✅ Load subreport correctly
            InputStream subReportStream = getClass().getClassLoader().getResourceAsStream(SUBREPORT_TEMPLATE);
            if (subReportStream == null) {
                throw new JRException("❌ Subreport template not found: " + SUBREPORT_TEMPLATE);
            }

            // Compile reports
            JasperReport mainReport = JasperCompileManager.compileReport(mainReportStream);
            JasperReport subreport = JasperCompileManager.compileReport(subReportStream);


            List<Map<String, Object>> subreportList = new ArrayList<>();

            Map<String, Object> subreport1 = new HashMap<>();
            subreport1.put("SubreportSource", subreport);
            subreport1.put("SubreportDataSource", subreportDataSource1);
            subreportList.add(subreport1);

            Map<String, Object> subreport2 = new HashMap<>();
            subreport2.put("SubreportSource", subreport);
            subreport2.put("SubreportDataSource", subreportDataSource2);
            subreportList.add(subreport2);


            // Create a main data source (JREmptyDataSource if no actual data is needed)
            JRDataSource mainDataSource = new JREmptyDataSource();

            Map<String, Object> parameters = new HashMap<>();
            parameters.put("SubreportList", subreportList);

            // Fill the main report
            JasperPrint jasperPrint = JasperFillManager.fillReport(mainReport, parameters, mainDataSource);

            // Set response headers
            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition", "attachment; filename=SubReport.pdf");

            // Export PDF
            JasperExportManager.exportReportToPdfStream(jasperPrint, response.getOutputStream());

            // Flush and close output stream
            response.getOutputStream().flush();
        } catch (Exception e) {
            e.printStackTrace();
            handleError(response, "Error generating report: " + e.getMessage(), e);
        }
    }

    public static JasperReport compileReport(String jrxmlPath) {
        try {
            // Compile the JRXML file and return the compiled JasperReport object
            return JasperCompileManager.compileReport(jrxmlPath);
        } catch (JRException e) {
            e.printStackTrace();
            throw new RuntimeException("Failed to compile JRXML file: " + jrxmlPath, e);
        }
    }

    public void generateSubreport(Map<String, Object> data, HttpServletResponse response) {
        try {
            List<Map<String, ?>> dataList = Collections.singletonList(data);

            JRMapCollectionDataSource dataSource = new JRMapCollectionDataSource(dataList);

            // ✅ Load JRXML file correctly from resources
            InputStream reportStream = getClass().getClassLoader().getResourceAsStream(ANKETA_TEMPLATE);
            if (reportStream == null) {
                throw new JRException("❌ Report template not found: " + ANKETA_TEMPLATE);
            }

            // Compile the report
            JasperReport jasperReport = JasperCompileManager.compileReport(reportStream);


            // Fill the report with data
            JasperPrint jasperPrint = JasperFillManager.fillReport(jasperReport, data, dataSource);


            // Set response headers
            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition", "attachment; filename=Anketa.pdf");

            // Export PDF
            JasperExportManager.exportReportToPdfStream(jasperPrint, response.getOutputStream());

            response.getOutputStream().flush();
        } catch (Exception e) {
            e.printStackTrace();
            handleError(response, "Error generating report: " + e.getMessage(), e);
        }
    }
}
