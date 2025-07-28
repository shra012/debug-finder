import time
import paramiko
import logging

logger = logging.getLogger(__name__)

class DebugPortFinderService:
    def __init__(self, servers):
        self.servers = servers

    def find_debug_port_users(self):
        result = {}
        for server in self.servers:
            server_name = server.get("name", "unknown")
            port_status = {}
            debug_ports = server.get("debugPorts", [])
            for port in debug_ports:
                info = self.get_remote_user_for_port(server, port)
                port_status[port] = info if info else "Not in use"
            result[server_name] = port_status
        return result

    def get_remote_user_for_port(self, server, port):
        hostname = server.get("hostname")
        if not hostname:
            return "No hostname"

        ssh_user = server.get("sshUser", "root")
        ssh_key_path = server.get("sshKeyPath", "")
        ssh_password = server.get("sshPassword", "")

        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        try:
            if ssh_key_path:
                key = paramiko.RSAKey.from_private_key_file(ssh_key_path)
                client.connect(hostname, username=ssh_user, pkey=key, timeout=5)
            else:
                client.connect(hostname, username=ssh_user, password=ssh_password, timeout=5)

            command = f"lsof -i :{port} -sTCP:ESTABLISHED -n -P"
            stdin, stdout, stderr = client.exec_command(command)
            # waiting for command execution
            time.sleep(0.5)
            output = stdout.read().decode().strip()
            if not output:
                return None

            # Look for a remote endpoint indicated by "->"
            for line in output.splitlines():
                if "->" in line:
                    arrow_index = line.index("->")
                    return "Connected: " + line[arrow_index + 2:].strip()
                elif line.startswith("u") and len(line) > 1:
                    return line[1:].strip()
            return "No active remote debug connection found"
        except Exception as e:
            logger.warning("Failed to check port %s on %s: %s", port, hostname, str(e))
            return "Error: " + str(e)
        finally:
            client.close()