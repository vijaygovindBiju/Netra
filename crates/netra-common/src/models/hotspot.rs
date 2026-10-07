use super::network::WifiBand;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HotspotConfig {
    pub ssid: String,
    pub passphrase: String,
    pub band: WifiBand,
    pub channel: Option<u16>,
    pub ap_isolate: bool,
}

impl Default for HotspotConfig {
    fn default() -> Self {
        Self {
            ssid: "Netra-Hotspot".to_string(),
            passphrase: "password1234".to_string(),
            band: WifiBand::Band24GHz,
            channel: None,
            ap_isolate: false,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum HotspotStatus {
    Inactive,
    Starting,
    Active,
    Stopping,
    Failed(String),
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum QoSPriority {
    High,
    Medium,
    Low,
}

impl QoSPriority {
    pub fn as_str(&self) -> &'static str {
        match self {
            QoSPriority::High => "High",
            QoSPriority::Medium => "Medium",
            QoSPriority::Low => "Low",
        }
    }

    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "high" => QoSPriority::High,
            "low" => QoSPriority::Low,
            _ => QoSPriority::Medium,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ConnectedClient {
    pub mac_address: String,
    pub ip_address: String,
    pub hostname: Option<String>,
    pub vendor: Option<String>,
    pub priority: QoSPriority,
    pub connected_duration_secs: u64,
    pub rx_rate_bps: u64,
    pub tx_rate_bps: u64,
    pub total_rx_bytes: u64,
    pub total_tx_bytes: u64,
}
