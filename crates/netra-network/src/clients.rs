use crate::oui::lookup_vendor;
use netra_common::models::hotspot::{ConnectedClient, QoSPriority};
use netra_common::{NetraError, Result};
use std::collections::HashMap;
use std::fs;
use std::time::Instant;

pub struct ClientTracker {
    // Maps MAC address to (connected_since, last_rx_bytes, last_tx_bytes, last_update)
    tracked_clients: HashMap<String, (Instant, u64, u64, Instant)>,
    priorities: HashMap<String, QoSPriority>,
}

impl ClientTracker {
    pub fn new() -> Self {
        Self {
            tracked_clients: HashMap::new(),
            priorities: HashMap::new(),
        }
    }

    pub fn set_priority(&mut self, mac: &str, priority: QoSPriority) {
        self.priorities.insert(mac.to_uppercase(), priority);
    }

    pub fn discover_clients(&mut self, hotspot_iface: &str) -> Result<Vec<ConnectedClient>> {
        let mut clients = Vec::new();
        let now = Instant::now();

        // 1. Read DHCP lease hostnames if available
        let hostnames = Self::read_dhcp_hostnames();

        // 2. Read active ARP cache
        let arp_content = fs::read_to_string("/proc/net/arp")
            .map_err(|e| NetraError::Io(e))?;

        for line in arp_content.lines().skip(1) {
            let parts: Vec<&str> = line.split_whitespace().collect();
            if parts.len() < 6 {
                continue;
            }

            let ip = parts[0];
            let flags = parts[2];
            let mac = parts[3].to_uppercase();
            let device = parts[5];

            // If a specific hotspot interface is provided, match it; otherwise accept any valid hotspot interface
            if !hotspot_iface.is_empty() && device != hotspot_iface {
                continue;
            }

            // Flag 0x2 indicates complete entry (ATF_COM)
            // Filter out empty/broadcast MACs
            if flags == "0x2" && mac != "00:00:00:00:00:00" && !mac.is_empty() {
                let vendor = lookup_vendor(&mac).map(|v| v.to_string());
                let hostname = hostnames.get(&mac).cloned();

                let priority = self.priorities.get(&mac).cloned().unwrap_or(QoSPriority::Medium);

                let (connected_since, last_rx, last_tx, last_time) = self
                    .tracked_clients
                    .entry(mac.clone())
                    .or_insert_with(|| (now, 0, 0, now));

                let connected_duration = (now - *connected_since).as_secs();
                let time_delta = (now - *last_time).as_secs_f64();

                // Compute instantaneous rates if possible
                let rx_rate = if time_delta > 0.1 {
                    0 // Refined via socket/tc stats in Phase 3
                } else {
                    0
                };
                let tx_rate = if time_delta > 0.1 {
                    0
                } else {
                    0
                };

                *last_time = now;

                clients.push(ConnectedClient {
                    mac_address: mac,
                    ip_address: ip.to_string(),
                    hostname,
                    vendor,
                    priority,
                    connected_duration_secs: connected_duration,
                    rx_rate_bps: rx_rate,
                    tx_rate_bps: tx_rate,
                    total_rx_bytes: *last_rx,
                    total_tx_bytes: *last_tx,
                });
            }
        }

        Ok(clients)
    }

    fn read_dhcp_hostnames() -> HashMap<String, String> {
        let mut hostnames = HashMap::new();

        // Check standard dnsmasq / NetworkManager lease locations
        let lease_paths = [
            "/var/lib/NetworkManager",
            "/var/lib/misc",
        ];

        for dir in lease_paths {
            if let Ok(entries) = fs::read_dir(dir) {
                for entry in entries.flatten() {
                    let path = entry.path();
                    if path.extension().and_then(|e| e.to_str()) == Some("leases")
                        || path.file_name().and_then(|n| n.to_str()).map_or(false, |n| n.starts_with("dnsmasq-"))
                    {
                        if let Ok(content) = fs::read_to_string(&path) {
                            for line in content.lines() {
                                let parts: Vec<&str> = line.split_whitespace().collect();
                                // dnsmasq lease format: <timestamp> <mac> <ip> <hostname> <client-id>
                                if parts.len() >= 4 {
                                    let mac = parts[1].to_uppercase();
                                    let hostname = parts[3];
                                    if hostname != "*" && !hostname.is_empty() {
                                        hostnames.insert(mac, hostname.to_string());
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        hostnames
    }
}
