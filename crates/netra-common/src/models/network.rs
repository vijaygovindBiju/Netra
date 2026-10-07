use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub enum WifiBand {
    Band24GHz,
    Band5GHz,
    Band6GHz,
    Unknown,
}

impl WifiBand {
    pub fn from_frequency(freq_mhz: u32) -> Self {
        match freq_mhz {
            2412..=2484 => WifiBand::Band24GHz,
            5170..=5825 => WifiBand::Band5GHz,
            5925..=7125 => WifiBand::Band6GHz,
            _ => WifiBand::Unknown,
        }
    }

    pub fn as_str(&self) -> &'static str {
        match self {
            WifiBand::Band24GHz => "2.4GHz",
            WifiBand::Band5GHz => "5GHz",
            WifiBand::Band6GHz => "6GHz",
            WifiBand::Unknown => "Unknown",
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum SecurityType {
    Open,
    WpaPsk,
    Wpa2Psk,
    Wpa3Sae,
    Enterprise,
}

impl SecurityType {
    pub fn as_str(&self) -> &'static str {
        match self {
            SecurityType::Open => "Open",
            SecurityType::WpaPsk => "WPA-PSK",
            SecurityType::Wpa2Psk => "WPA2-PSK",
            SecurityType::Wpa3Sae => "WPA3-SAE",
            SecurityType::Enterprise => "Enterprise",
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct AccessPointInfo {
    pub ssid: String,
    pub bssid: String,
    pub signal_strength: u8, // 0 - 100%
    pub frequency_mhz: u32,
    pub band: WifiBand,
    pub security: SecurityType,
    pub is_connected: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum InterfaceState {
    Disconnected,
    Connecting,
    Connected,
    Disconnecting,
    Failed,
    Unavailable,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InterfaceMetrics {
    pub iface_name: String,
    pub state: InterfaceState,
    pub is_wireless: bool,
    pub rx_bytes: u64,
    pub tx_bytes: u64,
    pub rx_rate_bps: u64,
    pub tx_rate_bps: u64,
    pub ip_address: Option<String>,
    pub gateway: Option<String>,
    pub dns_servers: Vec<String>,
    pub connected_ssid: Option<String>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_wifi_band_resolution() {
        assert_eq!(WifiBand::from_frequency(2412), WifiBand::Band24GHz);
        assert_eq!(WifiBand::from_frequency(2462), WifiBand::Band24GHz);
        assert_eq!(WifiBand::from_frequency(5180), WifiBand::Band5GHz);
        assert_eq!(WifiBand::from_frequency(5825), WifiBand::Band5GHz);
        assert_eq!(WifiBand::from_frequency(6000), WifiBand::Band6GHz);
        assert_eq!(WifiBand::from_frequency(900), WifiBand::Unknown);
    }

    #[test]
    fn test_security_type_strings() {
        assert_eq!(SecurityType::Open.as_str(), "Open");
        assert_eq!(SecurityType::Wpa2Psk.as_str(), "WPA2-PSK");
        assert_eq!(SecurityType::Wpa3Sae.as_str(), "WPA3-SAE");
    }
}

