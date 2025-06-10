package com.mig.debugfinder.handler;

import com.mig.debugfinder.service.DebugPortFinderService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class DebugPortHandler {

    private final DebugPortFinderService service;

    public DebugPortHandler(DebugPortFinderService service) {
        this.service = service;
    }

    @GetMapping("/debug-ports")
    public Map<String, Map<Integer, String>> getDebugPortUsers() {
        return service.findDebugPortUsers();
    }

    @GetMapping("/health")
    public String health() {
        return "UP";
    }
}