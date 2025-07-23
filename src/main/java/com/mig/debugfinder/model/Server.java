package com.mig.debugfinder.model;

import lombok.Data;

import java.util.List;

@Data
public class Server {
    private String name;
    private String hostname;
    private List<Integer> debugPorts;
    private String sshUser;
    private String sshKeyPath;
    private String sshPassword;
}