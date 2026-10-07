use netra_common::{NetraError, Result};
use std::process::Command;
use tracing::{error, info};

pub struct TrafficControlQoS;

impl TrafficControlQoS {
    /// Initializes an HTB root queueing discipline on an interface
    pub fn init_interface_htb(iface: &str) -> Result<()> {
        info!("Initializing TC HTB on interface: {}", iface);
        // Clear existing root qdisc if any
        let _ = Command::new("tc")
            .args(["qdisc", "del", "dev", iface, "root"])
            .output();

        // Add root HTB qdisc
        let output = Command::new("tc")
            .args(["qdisc", "add", "dev", iface, "root", "handle", "1:", "htb", "default", "30"])
            .output()
            .map_err(|e| NetraError::Io(e))?;

        if !output.status.success() {
            let err = String::from_utf8_lossy(&output.stderr);
            error!("Failed to create TC root qdisc: {}", err);
            return Err(NetraError::HotspotError(format!("tc init failed: {err}")));
        }

        // Add root class with 100mbit ceiling
        let _ = Command::new("tc")
            .args(["class", "add", "dev", iface, "parent", "1:", "classid", "1:1", "htb", "rate", "100mbit"])
            .output();

        // Add High priority class (1:10) - 60% bandwidth
        let _ = Command::new("tc")
            .args(["class", "add", "dev", iface, "parent", "1:1", "classid", "1:10", "htb", "rate", "60mbit", "ceil", "100mbit"])
            .output();

        // Add Medium priority class (1:20) - 30% bandwidth
        let _ = Command::new("tc")
            .args(["class", "add", "dev", iface, "parent", "1:1", "classid", "1:20", "htb", "rate", "30mbit", "ceil", "100mbit"])
            .output();

        // Add Low priority class (1:30) - 10% bandwidth
        let _ = Command::new("tc")
            .args(["class", "add", "dev", iface, "parent", "1:1", "classid", "1:30", "htb", "rate", "10mbit", "ceil", "50mbit"])
            .output();

        info!("TC HTB initialized successfully on {}", iface);
        Ok(())
    }

    /// Attaches an IP address to a priority class
    pub fn assign_ip_priority(iface: &str, ip: &str, priority: &str) -> Result<()> {
        let classid = match priority.to_lowercase().as_str() {
            "high" => "1:10",
            "low" => "1:30",
            _ => "1:20",
        };

        info!("Assigning IP {} to TC class {} on {}", ip, classid, iface);

        let output = Command::new("tc")
            .args([
                "filter", "add", "dev", iface, "protocol", "ip", "parent", "1:0", "prio", "1",
                "u32", "match", "ip", "dst", ip, "flowid", classid,
            ])
            .output()
            .map_err(|e| NetraError::Io(e))?;

        if !output.status.success() {
            let err = String::from_utf8_lossy(&output.stderr);
            error!("Failed to assign IP filter: {}", err);
            return Err(NetraError::HotspotError(format!("tc filter failed: {err}")));
        }

        Ok(())
    }

    /// Resets / removes TC rules from the interface
    pub fn reset_interface(iface: &str) -> Result<()> {
        info!("Resetting TC on interface: {}", iface);
        let _ = Command::new("tc")
            .args(["qdisc", "del", "dev", iface, "root"])
            .output();
        Ok(())
    }
}
