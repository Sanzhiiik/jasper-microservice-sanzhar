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
 * participants_ardak is the dynamic participants layout where every discipline column is split into
 * "оценка" (grade, red) and "балл" (score = grade x coefficient, black), followed by a single
 * "Итоговый балл" column (is_total). Like participants it is self-contained: it compiles its own
 * header/value subreports from the classpath and reads the dynamic columns from the data, so it needs
 * NO parameters from the backend. This fills it with an EMPTY parameter map (exactly what the service
 * passes for a standalone landscape report) for both a small (4) and a large (8) discipline set.
 */
class ParticipantsArdakTemplateTest {

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
        int total = 0;
        for (String name : names) {
            int grade = 2 + ((n + name.length()) % 4); // 2..5
            int coeff = 1 + (name.length() % 5);       // arbitrary demo coefficient
            int score = grade * coeff;
            total += score;
            Map<String, Object> d = new LinkedHashMap<>();
            d.put("name", name);
            d.put("grade", String.valueOf(grade));
            d.put("score", String.valueOf(score));
            disciplines.add(d);
        }
        Map<String, Object> totalRow = new LinkedHashMap<>();
        totalRow.put("name", "Итоговый балл");
        totalRow.put("score", String.valueOf(total));
        totalRow.put("is_total", true);
        disciplines.add(totalRow);
        c.put("disciplines", disciplines);
        return c;
    }

    private byte[] render(List<String> disciplineNames) throws Exception {
        JasperReport master = compile("participants_ardak");
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
    void rendersFourDisciplines() throws Exception {
        byte[] pdf = render(List.of("ППХ", "Письменные навыки", "Подтягивание", "КСУ"));
        assertTrue(pdf.length > 0);
        Files.write(Path.of("target/participants_ardak_4.pdf"), pdf);
    }

    @Test
    void rendersEightDisciplines() throws Exception {
        byte[] pdf = render(List.of(
                "ППХ", "Письменные навыки", "Политология", "Бег 2000/800м",
                "Бег 100м", "Подтягивание", "КСУ", "Спецдисциплина"));
        assertTrue(pdf.length > 0);
        Files.write(Path.of("target/participants_ardak_8.pdf"), pdf);
    }

    @Test
    void rendersTenDisciplines() throws Exception {
        // 10 disciplines + Итоговый балл = 11 columns, the new maximum that fits without wrapping.
        byte[] pdf = render(List.of(
                "ППХ", "Письменные навыки", "Политология", "Бег 2000/800м",
                "Бег 100м", "Подтягивание", "КСУ", "Спецдисциплина",
                "Иностранный язык", "Физподготовка"));
        assertTrue(pdf.length > 0);
        Files.write(Path.of("target/participants_ardak_10.pdf"), pdf);
    }
}
