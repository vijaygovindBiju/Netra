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

        Ok(BluetoothAdapterInfo {
            address,
            name,
            is_powered,
            is_discovering,
            is_pairable,
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
