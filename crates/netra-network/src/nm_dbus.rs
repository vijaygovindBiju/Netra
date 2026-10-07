use netra_common::models::hotspot::HotspotConfig;
use netra_common::models::network::{AccessPointInfo, SecurityType, WifiBand};
use netra_common::{NetraError, Result};
use std::collections::HashMap;
use tracing::{debug, info};
use zbus::zvariant::{ObjectPath, OwnedObjectPath, Value};
use zbus::Connection;

const NM_SERVICE: &str = "org.freedesktop.NetworkManager";
const NM_PATH: &str = "/org/freedesktop/NetworkManager";
const NM_IFACE: &str = "org.freedesktop.NetworkManager";
const NM_DEVICE_IFACE: &str = "org.freedesktop.NetworkManager.Device";
const NM_WIRELESS_IFACE: &str = "org.freedesktop.NetworkManager.Device.Wireless";
const NM_AP_IFACE: &str = "org.freedesktop.NetworkManager.AccessPoint";

const NM_DEVICE_TYPE_WIFI: u32 = 2;

pub struct NetworkManagerClient {
    connection: Connection,
    active_hotspot_path: Option<OwnedObjectPath>,
}

impl NetworkManagerClient {
    pub async fn new() -> Result<Self> {
        let connection = Connection::system().await
            .map_err(|e| NetraError::DBus(format!("Failed to connect to system bus: {e}")))?;
        Ok(Self {
            connection,
            active_hotspot_path: None,
        })
    }

    /// Finds the first wireless network interface name and object path
    pub async fn get_primary_wireless_device(&self) -> Result<(String, OwnedObjectPath)> {
        let proxy = zbus::Proxy::new(
            &self.connection,
            NM_SERVICE,
            NM_PATH,
            NM_IFACE,
        ).await.map_err(|e| NetraError::DBus(e.to_string()))?;

        let devices: Vec<OwnedObjectPath> = proxy.call("GetAllDevices", &()).await
            .map_err(|e| NetraError::DBus(format!("GetAllDevices call failed: {e}")))?;

        for dev_path in devices {
            let dev_proxy = zbus::Proxy::new(
                &self.connection,
                NM_SERVICE,
                dev_path.as_str(),
                NM_DEVICE_IFACE,
            ).await.map_err(|e| NetraError::DBus(e.to_string()))?;

            let dev_type: u32 = dev_proxy.get_property("DeviceType").await
                .unwrap_or(0);

            if dev_type == NM_DEVICE_TYPE_WIFI {
                let iface_name: String = dev_proxy.get_property("Interface").await
                    .unwrap_or_else(|_| "wlan0".to_string());
                return Ok((iface_name, dev_path));
            }
        }

        Err(NetraError::InterfaceNotFound("No wireless device found".into()))
    }

    /// Requests an active Wi-Fi scan on the given wireless device path
    pub async fn request_wifi_scan(&self, dev_path: &ObjectPath<'_>) -> Result<()> {
        let wireless_proxy = zbus::Proxy::new(
            &self.connection,
            NM_SERVICE,
            dev_path.as_str(),
            NM_WIRELESS_IFACE,
        ).await.map_err(|e| NetraError::DBus(e.to_string()))?;

        let options: HashMap<String, Value> = HashMap::new();
        wireless_proxy.call::<_, _, ()>("RequestScan", &(options)).await
            .map_err(|e| NetraError::ScanFailed(format!("RequestScan failed: {e}")))?;

        debug!("Wi-Fi scan successfully triggered");
        Ok(())
    }

    /// Retrieves all visible access points on the wireless device
    pub async fn get_access_points(&self, dev_path: &ObjectPath<'_>) -> Result<Vec<AccessPointInfo>> {
        let wireless_proxy = zbus::Proxy::new(
            &self.connection,
            NM_SERVICE,
            dev_path.as_str(),
            NM_WIRELESS_IFACE,
        ).await.map_err(|e| NetraError::DBus(e.to_string()))?;

        // Retrieve the currently active AP path if connected
        let active_ap_path: Option<OwnedObjectPath> = wireless_proxy
            .get_property("ActiveAccessPoint")
            .await
            .ok();

        let ap_paths: Vec<OwnedObjectPath> = wireless_proxy
            .call("GetAllAccessPoints", &())
            .await
            .unwrap_or_default();

        let mut ap_list = Vec::new();

        for ap_path in ap_paths {
            let ap_proxy = match zbus::Proxy::new(
                &self.connection,
                NM_SERVICE,
                ap_path.as_str(),
                NM_AP_IFACE,
            ).await {
                Ok(p) => p,
                Err(_) => continue,
            };

            let ssid_bytes: Vec<u8> = ap_proxy.get_property("Ssid").await.unwrap_or_default();
            let ssid = String::from_utf8_lossy(&ssid_bytes).to_string();

            // Skip hidden networks with empty SSIDs
            if ssid.trim().is_empty() {
                continue;
            }

            let bssid: String = ap_proxy.get_property("HwAddress").await.unwrap_or_default();
            let strength: u8 = ap_proxy.get_property("Strength").await.unwrap_or(0);
            let frequency: u32 = ap_proxy.get_property("Frequency").await.unwrap_or(2412);
            let wpa_flags: u32 = ap_proxy.get_property("WpaFlags").await.unwrap_or(0);
            let rsn_flags: u32 = ap_proxy.get_property("RsnFlags").await.unwrap_or(0);

            let security = if rsn_flags != 0 {
                if rsn_flags & 0x400 != 0 {
                    SecurityType::Wpa3Sae
                } else {
                    SecurityType::Wpa2Psk
                }
            } else if wpa_flags != 0 {
                SecurityType::WpaPsk
            } else {
                SecurityType::Open
            };

            let is_connected = active_ap_path.as_ref().map_or(false, |active| active == &ap_path);
            let band = WifiBand::from_frequency(frequency);

            ap_list.push(AccessPointInfo {
                ssid,
                bssid,
                signal_strength: strength,
                frequency_mhz: frequency,
                band,
                security,
                is_connected,
            });
        }

        // Sort access points by signal strength descending
        ap_list.sort_by(|a, b| b.signal_strength.cmp(&a.signal_strength));

        // Deduplicate SSIDs keeping strongest signal
        let mut unique_aps: HashMap<String, AccessPointInfo> = HashMap::new();
        for ap in ap_list {
            unique_aps.entry(ap.ssid.clone())
                .and_modify(|existing| {
                    if ap.signal_strength > existing.signal_strength {
                        *existing = ap.clone();
                    }
                })
                .or_insert(ap);
        }

        let mut final_list: Vec<AccessPointInfo> = unique_aps.into_values().collect();
        final_list.sort_by(|a, b| b.signal_strength.cmp(&a.signal_strength));

        Ok(final_list)
    }

    /// Connects to a Wi-Fi network with given SSID and Passphrase
    pub async fn connect_wifi(
        &self,
        dev_path: &ObjectPath<'_>,
        ssid: &str,
        passphrase: &str,
    ) -> Result<()> {
        let nm_proxy = zbus::Proxy::new(
            &self.connection,
            NM_SERVICE,
            NM_PATH,
            NM_IFACE,
        ).await.map_err(|e| NetraError::DBus(e.to_string()))?;

        let mut connection_map: HashMap<String, HashMap<String, Value>> = HashMap::new();

        // 1. Connection settings
        let mut conn_settings = HashMap::new();
        conn_settings.insert("id".to_string(), Value::new(ssid));
        conn_settings.insert("type".to_string(), Value::new("802-11-wireless"));
        conn_settings.insert("autoconnect".to_string(), Value::new(true));
        connection_map.insert("connection".to_string(), conn_settings);

        // 2. Wireless settings
        let mut wifi_settings = HashMap::new();
        wifi_settings.insert("ssid".to_string(), Value::new(ssid.as_bytes()));
        connection_map.insert("802-11-wireless".to_string(), wifi_settings);

        // 3. Security settings (if password provided)
        if !passphrase.is_empty() {
            let mut sec_settings = HashMap::new();
            sec_settings.insert("key-mgmt".to_string(), Value::new("wpa-psk"));
            sec_settings.insert("psk".to_string(), Value::new(passphrase));
            connection_map.insert("802-11-wireless-security".to_string(), sec_settings);
        }

        // 4. IPv4 auto
        let mut ipv4_settings = HashMap::new();
        ipv4_settings.insert("method".to_string(), Value::new("auto"));
        connection_map.insert("ipv4".to_string(), ipv4_settings);

        // 5. IPv6 auto
        let mut ipv6_settings = HashMap::new();
        ipv6_settings.insert("method".to_string(), Value::new("auto"));
        connection_map.insert("ipv6".to_string(), ipv6_settings);

        let specific_object = ObjectPath::try_from("/")
            .map_err(|e| NetraError::DBus(e.to_string()))?;

        info!("Calling AddAndActivateConnection for SSID: {}", ssid);
        let _res: (OwnedObjectPath, OwnedObjectPath) = nm_proxy
            .call(
                "AddAndActivateConnection",
                &(connection_map, dev_path, &specific_object),
            )
            .await
            .map_err(|e| NetraError::ConnectionFailed(format!("Failed to connect to Wi-Fi: {e}")))?;

        info!("Connection to {} initiated successfully", ssid);
        Ok(())
    }

    /// Disconnects the active wireless connection
    pub async fn disconnect_wifi(&self, dev_path: &ObjectPath<'_>) -> Result<()> {
        let dev_proxy = zbus::Proxy::new(
            &self.connection,
            NM_SERVICE,
            dev_path.as_str(),
            NM_DEVICE_IFACE,
        ).await.map_err(|e| NetraError::DBus(e.to_string()))?;

        dev_proxy.call::<_, _, ()>("Disconnect", &()).await
            .map_err(|e| NetraError::ConnectionFailed(format!("Failed to disconnect: {e}")))?;

        info!("Disconnected Wi-Fi successfully");
        Ok(())
    }

    /// Starts a Hotspot in AP mode on the wireless device
    pub async fn start_hotspot(
        &mut self,
        dev_path: &ObjectPath<'_>,
        config: &HotspotConfig,
    ) -> Result<()> {
        // Disconnect existing hotspot if active
        if self.active_hotspot_path.is_some() {
            self.stop_hotspot().await?;
        }

        let nm_proxy = zbus::Proxy::new(
            &self.connection,
            NM_SERVICE,
            NM_PATH,
            NM_IFACE,
        ).await.map_err(|e| NetraError::DBus(e.to_string()))?;

        let mut connection_map: HashMap<String, HashMap<String, Value>> = HashMap::new();

        // 1. Connection settings
        let mut conn_settings = HashMap::new();
        conn_settings.insert("id".to_string(), Value::new("Netra-Hotspot"));
        conn_settings.insert("type".to_string(), Value::new("802-11-wireless"));
        conn_settings.insert("autoconnect".to_string(), Value::new(false));
        connection_map.insert("connection".to_string(), conn_settings);

        // 2. Wireless settings (AP mode)
        let mut wifi_settings = HashMap::new();
        wifi_settings.insert("ssid".to_string(), Value::new(config.ssid.as_bytes()));
        wifi_settings.insert("mode".to_string(), Value::new("ap"));
        let band_str = match config.band {
            WifiBand::Band5GHz => "a",
            _ => "bg",
        };
        wifi_settings.insert("band".to_string(), Value::new(band_str));
        if let Some(ch) = config.channel {
            wifi_settings.insert("channel".to_string(), Value::new(ch as u32));
        }
        connection_map.insert("802-11-wireless".to_string(), wifi_settings);

        // 3. Wireless security
        let mut sec_settings = HashMap::new();
        sec_settings.insert("key-mgmt".to_string(), Value::new("wpa-psk"));
        sec_settings.insert("psk".to_string(), Value::new(config.passphrase.as_str()));
        connection_map.insert("802-11-wireless-security".to_string(), sec_settings);

        // 4. Shared IPv4
        let mut ipv4_settings = HashMap::new();
        ipv4_settings.insert("method".to_string(), Value::new("shared"));
        connection_map.insert("ipv4".to_string(), ipv4_settings);

        // 5. Ignore IPv6
        let mut ipv6_settings = HashMap::new();
        ipv6_settings.insert("method".to_string(), Value::new("ignore"));
        connection_map.insert("ipv6".to_string(), ipv6_settings);

        let specific_object = ObjectPath::try_from("/")
            .map_err(|e| NetraError::DBus(e.to_string()))?;

        info!("Starting Hotspot SSID: {} on band: {:?}", config.ssid, config.band);
        let (_conn_path, active_conn): (OwnedObjectPath, OwnedObjectPath) = nm_proxy
            .call(
                "AddAndActivateConnection",
                &(connection_map, dev_path, &specific_object),
            )
            .await
            .map_err(|e| NetraError::HotspotError(format!("Failed to activate Hotspot: {e}")))?;

        info!("Hotspot activated with path: {}", active_conn);
        self.active_hotspot_path = Some(active_conn);
        Ok(())
    }

    /// Stops the active Hotspot
    pub async fn stop_hotspot(&mut self) -> Result<()> {
        if let Some(active_conn) = self.active_hotspot_path.take() {
            let nm_proxy = zbus::Proxy::new(
                &self.connection,
                NM_SERVICE,
                NM_PATH,
                NM_IFACE,
            ).await.map_err(|e| NetraError::DBus(e.to_string()))?;

            info!("Deactivating hotspot connection: {}", active_conn);
            let _: () = nm_proxy
                .call::<_, _, ()>("DeactivateConnection", &(&active_conn,))
                .await
                .map_err(|e| NetraError::HotspotError(format!("Failed to deactivate hotspot: {e}")))?;

            info!("Hotspot stopped successfully");
        }
        Ok(())
    }

    pub fn is_hotspot_active(&self) -> bool {
        self.active_hotspot_path.is_some()
    }
}
