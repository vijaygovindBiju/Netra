use netra_common::models::bluetooth::{BluetoothAdapterInfo, BluetoothDevice, DeviceCategory};
use netra_common::{NetraError, Result};
use std::collections::HashMap;
use tracing::info;
use zbus::zvariant::{OwnedObjectPath, OwnedValue, Value};
use zbus::Connection;

const BLUEZ_SERVICE: &str = "org.bluez";
const OM_IFACE: &str = "org.freedesktop.DBus.ObjectManager";
const ADAPTER_IFACE: &str = "org.bluez.Adapter1";
const DEVICE_IFACE: &str = "org.bluez.Device1";
const BATTERY_IFACE: &str = "org.bluez.Battery1";

fn get_str_prop(props: &HashMap<String, OwnedValue>, key: &str) -> String {
    if let Some(val) = props.get(key) {
        if let Value::Str(s) = &**val {
            return s.as_str().to_string();
        }
    }
    String::new()
}

fn get_bool_prop(props: &HashMap<String, OwnedValue>, key: &str) -> bool {
    if let Some(val) = props.get(key) {
        if let Value::Bool(b) = &**val {
            return *b;
        }
    }
    false
}

fn get_u32_prop(props: &HashMap<String, OwnedValue>, key: &str) -> u32 {
    if let Some(val) = props.get(key) {
        if let Value::U32(u) = &**val {
            return *u;
        }
    }
    0
}

fn get_i16_prop(props: &HashMap<String, OwnedValue>, key: &str) -> Option<i16> {
    if let Some(val) = props.get(key) {
        if let Value::I16(i) = &**val {
            return Some(*i);
        }
    }
    None
}

fn get_u8_prop(props: &HashMap<String, OwnedValue>, key: &str) -> Option<u8> {
    if let Some(val) = props.get(key) {
        if let Value::U8(u) = &**val {
            return Some(*u);
        }
    }
    None
}

fn map_manufacturer(id: u16) -> &'static str {
    match id {
        0 => "Ericsson",
        2 => "Intel",
        10 => "Qualcomm",
        13 => "Texas Instruments",
        15 => "Broadcom",
        29 => "Qualcomm / Atheros",
        48 => "Realtek",
        70 => "MediaTek",
        76 => "Apple",
        131 => "Qualcomm (CSR)",
        224 => "Nordic Semiconductor",
        _ => "Unknown Manufacturer",
    }
}

fn map_bluetooth_version(hci_version: u8) -> &'static str {
    match hci_version {
        0 => "1.0b",
        1 => "1.1",
        2 => "1.2",
        3 => "2.0 + EDR",
        4 => "2.1 + EDR",
        5 => "3.0 + HS",
        6 => "4.0",
        7 => "4.1",
        8 => "4.2",
        9 => "5.0",
        10 => "5.1",
        11 => "5.2",
        12 => "5.3",
        13 => "5.4",
        14 => "6.0",
        _ if hci_version > 14 => "6.0+",
        _ => "Legacy",
    }
}

fn detect_chipset_name(manufacturer: &str, hci_version: u8) -> String {
    if let Ok(entries) = std::fs::read_dir("/sys/class/bluetooth") {
        for entry in entries.flatten() {
            let path = entry.path();
            let device_path = path.join("device");
            let candidates = [device_path.join(".."), device_path];
            for cand in candidates {
                let v_file = cand.join("idVendor");
                let p_file = cand.join("idProduct");
                if let (Ok(v), Ok(p)) = (std::fs::read_to_string(&v_file), std::fs::read_to_string(&p_file)) {
                    let vendor = v.trim().to_lowercase();
                    let product = p.trim().to_lowercase();

                    for ids_path in ["/usr/share/hwdata/usb.ids", "/var/lib/usbutils/usb.ids"] {
                        if let Ok(content) = std::fs::read_to_string(ids_path) {
                            let mut in_vendor = false;
                            for line in content.lines() {
                                if line.starts_with(&vendor) {
                                    in_vendor = true;
                                    continue;
                                } else if in_vendor {
                                    if line.starts_with("\t\t") {
                                        continue;
                                    }
                                    if line.starts_with('\t') {
                                        let trimmed = line.trim_start_matches('\t');
                                        if let Some((prod_id, prod_name)) = trimmed.split_once("  ") {
                                            if prod_id.trim().eq_ignore_ascii_case(&product) {
                                                return prod_name.trim().to_string();
                                            }
                                        }
                                    } else if !line.starts_with('#') {
                                        break;
                                    }
                                }
                            }
                        }
                    }

                    let matched = match (vendor.as_str(), product.as_str()) {
                        ("04ca", "3802") | ("0e8d", "0608") => "MediaTek MT7921",
                        ("0e8d", "0616") => "MediaTek MT7922",
                        ("8087", "0026") => "Intel Wi-Fi 6 AX200 / AX201",
                        ("8087", "0032") => "Intel Wi-Fi 6E AX210",
                        ("8087", "0033") => "Intel Wi-Fi 6E AX211",
                        ("8087", "0036") => "Intel Wi-Fi 7 BE200",
                        ("0bda", "b852") => "Realtek RTL8852AE",
                        ("0bda", "c852") => "Realtek RTL8852BE",
                        _ => "",
                    };
                    if !matched.is_empty() {
                        return matched.to_string();
                    }
                }
            }
        }
    }

    if manufacturer != "Unknown Manufacturer" && !manufacturer.is_empty() {
        format!("{manufacturer} Bluetooth Adapter (BT {})", map_bluetooth_version(hci_version))
    } else {
        format!("Generic Bluetooth Adapter (BT {})", map_bluetooth_version(hci_version))
    }
}


pub struct BluezClient {
    connection: Connection,
    primary_adapter_path: Option<OwnedObjectPath>,
}

impl BluezClient {
    pub async fn new() -> Result<Self> {
        let connection = Connection::system().await
            .map_err(|e| NetraError::DBus(format!("Failed to connect to system bus: {e}")))?;

        let mut client = Self {
            connection,
            primary_adapter_path: None,
        };

        client.refresh_adapter().await?;
        Ok(client)
    }

    pub async fn refresh_adapter(&mut self) -> Result<()> {
        let om_proxy = zbus::Proxy::new(
            &self.connection,
            BLUEZ_SERVICE,
            "/",
            OM_IFACE,
        ).await.map_err(|e| NetraError::DBus(e.to_string()))?;

        let managed: HashMap<OwnedObjectPath, HashMap<String, HashMap<String, OwnedValue>>> =
            om_proxy.call("GetManagedObjects", &()).await
                .unwrap_or_default();

        for (path, ifaces) in managed {
            if ifaces.contains_key(ADAPTER_IFACE) {
                info!("Found Bluetooth adapter at path: {}", path);
                self.primary_adapter_path = Some(path);
                return Ok(());
            }
        }

        self.primary_adapter_path = None;
        Ok(())
    }

    pub fn get_adapter_path(&self) -> Result<&OwnedObjectPath> {
        self.primary_adapter_path.as_ref().ok_or_else(|| {
            NetraError::InterfaceNotFound("No Bluetooth adapter found on system".into())
        })
    }

    pub async fn get_adapter_info(&self) -> Result<BluetoothAdapterInfo> {
        let path = self.get_adapter_path()?;
        let proxy = zbus::Proxy::new(
            &self.connection,
            BLUEZ_SERVICE,
            path.as_str(),
            ADAPTER_IFACE,
        ).await.map_err(|e| NetraError::DBus(e.to_string()))?;

        let address: String = proxy.get_property("Address").await.unwrap_or_default();
        let name: String = proxy.get_property("Alias").await
            .unwrap_or_else(|_| "Bluetooth Adapter".to_string());
        let is_powered: bool = proxy.get_property("Powered").await.unwrap_or(false);
        let is_discovering: bool = proxy.get_property("Discovering").await.unwrap_or(false);
        let is_pairable: bool = proxy.get_property("Pairable").await.unwrap_or(false);

        let hci_version: u8 = proxy.get_property("Version").await.unwrap_or(9);
        let manufacturer_id: u16 = proxy.get_property("Manufacturer").await.unwrap_or(0);
        let manufacturer = map_manufacturer(manufacturer_id).to_string();
        let bluetooth_version = map_bluetooth_version(hci_version).to_string();
        let chipset_name = detect_chipset_name(&manufacturer, hci_version);

        // Standard Bluetooth Central/Master Piconet physical capacity is 7 concurrent active links
        let max_active_connections = 7u8;

        // Calculate practical audio streaming capacity before radio time-slicing packet loss
        let max_recommended_audio_streams = if hci_version >= 11 {
            // Bluetooth 5.2, 5.3, 5.4 with 2M PHY & LE Audio
            3u8
        } else if hci_version >= 9 {
            // Bluetooth 5.0, 5.1
            2u8
        } else {
            // Bluetooth 4.x
            2u8
        };

        let supports_le_audio = hci_version >= 11;
        let supports_2m_phy = hci_version >= 9;

        Ok(BluetoothAdapterInfo {
            address,
            name,
            is_powered,
            is_discovering,
            is_pairable,
            manufacturer,
            chipset_name,
            bluetooth_version,
            hci_version,
            max_active_connections,
            max_recommended_audio_streams,
            supports_le_audio,
            supports_2m_phy,
        })
    }

    pub async fn start_discovery(&self) -> Result<()> {
        let path = self.get_adapter_path()?;
        let proxy = zbus::Proxy::new(
            &self.connection,
            BLUEZ_SERVICE,
            path.as_str(),
            ADAPTER_IFACE,
        ).await.map_err(|e| NetraError::DBus(e.to_string()))?;

        proxy.call::<_, _, ()>("StartDiscovery", &()).await
            .map_err(|e| NetraError::DBus(format!("StartDiscovery failed: {e}")))?;

        info!("Bluetooth discovery started");
        Ok(())
    }

    pub async fn stop_discovery(&self) -> Result<()> {
        let path = self.get_adapter_path()?;
        let proxy = zbus::Proxy::new(
            &self.connection,
            BLUEZ_SERVICE,
            path.as_str(),
            ADAPTER_IFACE,
        ).await.map_err(|e| NetraError::DBus(e.to_string()))?;

        proxy.call::<_, _, ()>("StopDiscovery", &()).await
            .map_err(|e| NetraError::DBus(format!("StopDiscovery failed: {e}")))?;

        info!("Bluetooth discovery stopped");
        Ok(())
    }

    pub async fn set_powered(&self, powered: bool) -> Result<()> {
        let path = self.get_adapter_path()?;
        let proxy = zbus::Proxy::new(
            &self.connection,
            BLUEZ_SERVICE,
            path.as_str(),
            ADAPTER_IFACE,
        ).await.map_err(|e| NetraError::DBus(e.to_string()))?;

        proxy.set_property("Powered", powered).await
            .map_err(|e| NetraError::DBus(format!("Set Powered failed: {e}")))?;

        info!("Bluetooth adapter powered set to: {}", powered);
        Ok(())
    }

    pub async fn get_devices(&self) -> Result<Vec<BluetoothDevice>> {
        let om_proxy = zbus::Proxy::new(
            &self.connection,
            BLUEZ_SERVICE,
            "/",
            OM_IFACE,
        ).await.map_err(|e| NetraError::DBus(e.to_string()))?;

        let managed: HashMap<OwnedObjectPath, HashMap<String, HashMap<String, OwnedValue>>> =
            om_proxy.call("GetManagedObjects", &()).await
                .map_err(|e| NetraError::DBus(format!("GetManagedObjects failed: {e}")))?;

        let mut devices = Vec::new();

        for (_path, ifaces) in &managed {
            if let Some(dev_props) = ifaces.get(DEVICE_IFACE) {
                let address = get_str_prop(dev_props, "Address");
                if address.is_empty() {
                    continue;
                }

                let mut name = get_str_prop(dev_props, "Name");
                if name.is_empty() {
                    name = address.clone();
                }

                let mut alias = get_str_prop(dev_props, "Alias");
                if alias.is_empty() {
                    alias = name.clone();
                }

                let icon = get_str_prop(dev_props, "Icon");
                let class = get_u32_prop(dev_props, "Class");
                let is_paired = get_bool_prop(dev_props, "Paired");
                let is_connected = get_bool_prop(dev_props, "Connected");
                let is_trusted = get_bool_prop(dev_props, "Trusted");
                let rssi = get_i16_prop(dev_props, "RSSI");

                let battery_percentage = ifaces.get(BATTERY_IFACE)
                    .and_then(|b| get_u8_prop(b, "Percentage"));

                let category = DeviceCategory::from_icon_or_class(&icon, class);

                devices.push(BluetoothDevice {
                    address,
                    name,
                    alias,
                    category,
                    is_paired,
                    is_connected,
                    is_trusted,
                    battery_percentage,
                    rssi,
                    uuids: Vec::new(),
                });
            }
        }

        devices.sort_by(|a, b| {
            b.is_connected.cmp(&a.is_connected)
                .then_with(|| b.is_paired.cmp(&a.is_paired))
                .then_with(|| a.alias.cmp(&b.alias))
        });

        Ok(devices)
    }

    fn device_address_to_path(&self, address: &str) -> Result<OwnedObjectPath> {
        let adapter_path = self.get_adapter_path()?;
        let formatted_mac = address.replace(':', "_").to_uppercase();
        let path_str = format!("{}/dev_{}", adapter_path.as_str(), formatted_mac);
        OwnedObjectPath::try_from(path_str).map_err(|e| NetraError::DBus(e.to_string()))
    }

    pub async fn connect_device(&self, address: &str) -> Result<()> {
        let dev_path = self.device_address_to_path(address)?;
        let proxy = zbus::Proxy::new(
            &self.connection,
            BLUEZ_SERVICE,
            dev_path.as_str(),
            DEVICE_IFACE,
        ).await.map_err(|e| NetraError::DBus(e.to_string()))?;

        info!("Connecting Bluetooth device: {}", address);
        proxy.call::<_, _, ()>("Connect", &()).await
            .map_err(|e| NetraError::ConnectionFailed(format!("Connect failed: {e}")))?;

        info!("Connected to Bluetooth device: {}", address);
        Ok(())
    }

    pub async fn disconnect_device(&self, address: &str) -> Result<()> {
        let dev_path = self.device_address_to_path(address)?;
        let proxy = zbus::Proxy::new(
            &self.connection,
            BLUEZ_SERVICE,
            dev_path.as_str(),
            DEVICE_IFACE,
        ).await.map_err(|e| NetraError::DBus(e.to_string()))?;

        info!("Disconnecting Bluetooth device: {}", address);
        proxy.call::<_, _, ()>("Disconnect", &()).await
            .map_err(|e| NetraError::ConnectionFailed(format!("Disconnect failed: {e}")))?;

        info!("Disconnected Bluetooth device: {}", address);
        Ok(())
    }

    pub async fn pair_device(&self, address: &str) -> Result<()> {
        let dev_path = self.device_address_to_path(address)?;
        let proxy = zbus::Proxy::new(
            &self.connection,
            BLUEZ_SERVICE,
            dev_path.as_str(),
            DEVICE_IFACE,
        ).await.map_err(|e| NetraError::DBus(e.to_string()))?;

        info!("Pairing Bluetooth device: {}", address);
        proxy.call::<_, _, ()>("Pair", &()).await
            .map_err(|e| NetraError::ConnectionFailed(format!("Pair failed: {e}")))?;

        let _ = proxy.set_property("Trusted", true).await;
        info!("Paired Bluetooth device: {}", address);
        Ok(())
    }

    pub async fn remove_device(&self, address: &str) -> Result<()> {
        let adapter_path = self.get_adapter_path()?;
        let dev_path = self.device_address_to_path(address)?;

        let adapter_proxy = zbus::Proxy::new(
            &self.connection,
            BLUEZ_SERVICE,
            adapter_path.as_str(),
            ADAPTER_IFACE,
        ).await.map_err(|e| NetraError::DBus(e.to_string()))?;

        adapter_proxy.call::<_, _, ()>("RemoveDevice", &(&dev_path,)).await
            .map_err(|e| NetraError::DBus(format!("RemoveDevice failed: {e}")))?;

        info!("Removed Bluetooth device: {}", address);
        Ok(())
    }
}
