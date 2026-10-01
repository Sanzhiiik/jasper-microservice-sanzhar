package com.example.jaspertable;

import net.sf.jasperreports.engine.*;
import net.sf.jasperreports.engine.data.JRMapCollectionDataSource;
import org.junit.jupiter.api.Test;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

/**
 * The participants template is self-contained: it compiles its discipline subreports from the
 * classpath and reads the dynamic column headers from the data, so it needs NO parameters from the
 * backend. This test fills it with an EMPTY parameter map (exactly what the current service passes
 * for a standalone landscape report) for both a small (3) and a large (8) discipline set.
 */
class ParticipantsDynamicTemplateTest {

    private JasperReport compile(String key) throws Exception {
        try (InputStream is = getClass().getClassLoader()
                .getResourceAsStream("reports/report/" + key + ".jrxml")) {
            assertNotNull(is, "template not found on classpath: " + key);
            return JasperCompileManager.compileReport(is);
        }
    }

    private Map<String, Object> candidate(int n, List<String> names) {
        Map<String, Object> c = new LinkedHashMap<>();
        c.put("iin", "00000000000" + n);
        c.put("fio", "Кандидат " + n + " Тест Тестович");
        c.put("birth_date", "01.01.1995 (30 лет)");
        c.put("direction", "Направление " + n);
        c.put("study_division", "ОНБ по области");
        c.put("selection_period", "1-5 сентября 2026");
        List<Map<String, Object>> disciplines = new ArrayList<>();
        for (String name : names) {
            Map<String, Object> d = new LinkedHashMap<>();
            d.put("name", name);
            d.put("value", (n % 2 == 0) ? "5 / 25" : "4");
            disciplines.add(d);
        }
        Map<String, Object> total = new LinkedHashMap<>();
        total.put("name", "Итоговые баллы");
        total.put("value", String.valueOf(100 + n));
        total.put("is_total", true);
        disciplines.add(total);
        c.put("disciplines", disciplines);
        return c;
    }

    private byte[] render(List<String> disciplineNames) throws Exception {
        JasperReport master = compile("participants");
        List<Map<String, ?>> rows = new ArrayList<>();
        for (int i = 1; i <= 3; i++) {
            rows.add(candidate(i, disciplineNames));
        }
        // No parameters — the template is fully self-contained.
        JasperPrint print = JasperFillManager.fillReport(
                master, new HashMap<>(), new JRMapCollectionDataSource(rows));
        return JasperExportManager.exportReportToPdf(print);
    }

    @Test
    void rendersThreeDisciplines() throws Exception {
        byte[] pdf = render(List.of("ППХ", "Политология", "Бег 100м"));
        assertTrue(pdf.length > 0);
        Files.write(Path.of("target/participants_3.pdf"), pdf);
    }

    @Test
    void rendersEightDisciplines() throws Exception {
        byte[] pdf = render(List.of(
                "ППХ", "Письменные навыки", "Политология", "Бег 2000/800м",
                "Бег 100м", "Подтягивание/КСУ", "Спецдисциплина", "Иностранный язык"));
        assertTrue(pdf.length > 0);
        Files.write(Path.of("target/participants_8.pdf"), pdf);
    }
}
