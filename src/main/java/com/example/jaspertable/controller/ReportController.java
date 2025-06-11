package com.example.jaspertable.controller;

import com.example.jaspertable.service.JReportService;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
@RequestMapping("/generate/report")
public class ReportController {

    private final JReportService jReportService;



    @GetMapping("/{file_name}")
    public void generateResultsReport(@RequestBody LinkedHashMap<String, List<Map<String, Object>>> requestBody, @PathVariable("file_name") String file_name, HttpServletResponse response) throws IOException, Exception {
        jReportService.automated(file_name, requestBody, response);
    }




}
