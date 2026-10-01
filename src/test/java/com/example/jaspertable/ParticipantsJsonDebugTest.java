package com.example.jaspertable;

import com.fasterxml.jackson.databind.ObjectMapper;
import net.sf.jasperreports.engine.*;
import net.sf.jasperreports.engine.data.JRMapCollectionDataSource;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.junit.jupiter.api.Test;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.InputStream;
import java.util.*;

/** Reproduces the real request path: parse participants.json exactly like the controller and render. */
class ParticipantsJsonDebugTest {

    private JasperReport compile(String key) throws Exception {
        try (InputStream is = getClass().getClassLoader().getResourceAsStream("reports/report/" + key + ".jrxml")) {
            return JasperCompileManager.compileReport(is);
        }
    }

    @Test
    @SuppressWarnings("unchecked")
    void renderFromJson() throws Exception {
        ObjectMapper om = new ObjectMapper();
        Map<String, Object> body = om.readValue(
                new File("src/main/resources/reports/json/participants.json"), Map.class);
        List<Map<String, Object>> values = (List<Map<String, Object>>) body.get("participants");
        System.out.println("CANDIDATES=" + values.size());
        System.out.println("FIRST DISCIPLINES=" + values.get(0).get("disciplines"));

        JasperReport master = compile("participants");
        Map<String, Object> params = new HashMap<>();
        params.put("DISCIPLINES_SUBREPORT", compile("participants_disciplines"));
        params.put("DISCIPLINE_HEADER_SUBREPORT", compile("participants_disciplines_header"));

        List<Map<String, ?>> headerRows = new ArrayList<>();
        for (Object d : (Collection<?>) values.get(0).get("disciplines")) {
            Map<String, Object> h = new HashMap<>();
            h.put("name", ((Map<?, ?>) d).get("name"));
            headerRows.add(h);
        }
        System.out.println("HEADER COUNT=" + headerRows.size());
        params.put("DISCIPLINE_HEADERS", headerRows);

        JasperPrint print = JasperFillManager.fillReport(
                master, params, new JRMapCollectionDataSource(new ArrayList<Map<String, ?>>(values)));
        byte[] pdf = JasperExportManager.exportReportToPdf(print);
        File out = new File("target/participants_json.pdf");
        java.nio.file.Files.write(out.toPath(), pdf);
        try (PDDocument doc = PDDocument.load(out)) {
            BufferedImage img = new PDFRenderer(doc).renderImageWithDPI(0, 130);
            ImageIO.write(img, "png", new File("target/participants_json.png"));
        }
    }
}
