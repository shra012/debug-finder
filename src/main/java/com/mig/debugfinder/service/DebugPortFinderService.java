package com.mig.debugfinder.service;

import com.mig.debugfinder.configuration.DebugFinderProperties;
import com.mig.debugfinder.model.Server;
import com.jcraft.jsch.ChannelExec;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.Session;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class DebugPortFinderService {

    private static final Logger logger = LoggerFactory.getLogger(DebugPortFinderService.class);
    private final DebugFinderProperties debugFinderProperties;

    public DebugPortFinderService(DebugFinderProperties debugFinderProperties) {
        this.debugFinderProperties = debugFinderProperties;
    }

    /**
     * Returns a map: serverName -> (port -> user/connection info)
     */
    public Map<String, Map<Integer, String>> findDebugPortUsers() {
        Map<String, Map<Integer, String>> result = new LinkedHashMap<>();
        List<Server> servers = debugFinderProperties.getServers();

        if (servers == null) {
            logger.warn("No servers configured.");
            return result;
        }

        for (Server server : servers) {
            Map<Integer, String> portStatus = new LinkedHashMap<>();
            if (server.getDebugPorts() == null) continue;
            for (Integer port : server.getDebugPorts()) {
                String info = getRemoteUserForPort(server.getHostname(), port);
                portStatus.put(port, info != null ? info : "Not in use");
            }
            result.put(server.getName(), portStatus);
        }
        return result;
    }

    /**
     * SSH into the remote host and run a single lsof command.
     * It checks for an established connection (indicated by "->") or returns the local user.
     */
    private String getRemoteUserForPort(String hostname, int port) {
        if (hostname == null || hostname.isEmpty()) return "No hostname";

        Session session = null;
        ChannelExec channel = null;
        try {
            JSch jsch = new JSch();
            jsch.addIdentity("");
            String sshUser = "root";
            session = jsch.getSession(sshUser, hostname, 22);
            session.setConfig("StrictHostKeyChecking", "no");
            session.connect(5000);

            // Use a single lsof command to get connection details
            String command = String.format("lsof -i :%d -sTCP:ESTABLISHED", port);
            channel = (ChannelExec) session.openChannel("exec");
            channel.setCommand(command);
            channel.setInputStream(null);
            InputStream in = channel.getInputStream();
            channel.connect();

            StringBuilder output = new StringBuilder();
            byte[] buffer = new byte[1024];
            while (true) {
                while (in.available() > 0) {
                    int read = in.read(buffer);
                    if (read < 0) break;
                    output.append(new String(buffer, 0, read));
                }
                if (channel.isClosed()) break;
                Thread.sleep(100);
            }
            String result = output.toString().trim();
            if (result.isEmpty()) return null;
            for (String line : result.split("\\R")) {
                if (line.contains("->")) { // found remote endpoint info
                    int arrowIdx = line.indexOf("->");
                    return "Connected: " + line.substring(arrowIdx + 2).trim();
                } else if (line.startsWith("u") && line.length() > 1) { // found local user info
                    return line.substring(1).trim();
                }
            }
        } catch (Exception e) {
            logger.warn("Failed to check port {} on {}: {}", port, hostname, e.getMessage());
            return "Error: " + e.getMessage();
        } finally {
            if (channel != null) channel.disconnect();
            if (session != null) session.disconnect();
        }
        return null;
    }
}